import SwiftUI
import CoreLocation
import FirebaseAuth
import FirebaseFirestore

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            locationManager.stopUpdatingLocation()
            location = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
        locationManager.stopUpdatingLocation()
    }
}

struct LocationPermissionView: View {
    @Binding var isAuthenticated: Bool
    @Binding var currentStep: Int
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var locationManager = LocationManager()
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let db = Firestore.firestore()
    
    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color("Gold"))
                            .padding(.bottom, 8)
                            .symbolEffect(.bounce, options: .repeating)
                        
                        Text("Enable Location Services")
                            .font(.custom("Lora-Regular", size: 24))
                            .foregroundColor(Color.accent)
                        
                        Text("This helps us find matches near you")
                            .font(.custom("Lora-Regular", size: 16))
                            .foregroundColor(Color.accent.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                    
                    // Progress indicator
                    SignupProgressView(currentStep: currentStep)
                    
                    // Location Status
                    VStack(spacing: 20) {
                        if let status = locationManager.authorizationStatus {
                            switch status {
                            case .notDetermined:
                                requestLocationButton
                            case .restricted, .denied:
                                deniedLocationView
                            case .authorizedWhenInUse, .authorizedAlways:
                                if locationManager.location != nil {
                                    locationGrantedView
                                } else {
                                    ProgressView("Getting your location...")
                                        .tint(Color("Gold"))
                                }
                            @unknown default:
                                Text("Unknown status")
                                    .foregroundColor(Color.accent)
                            }
                        } else {
                            requestLocationButton
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Continue button
                    if locationManager.authorizationStatus == .authorizedWhenInUse ||
                       locationManager.authorizationStatus == .authorizedAlways {
                        VStack(spacing: 16) {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(1.2)
                            } else {
                                Button(action: saveLocationAndContinue) {
                                    HStack {
                                        Text("Continue")
                                            .font(.system(size: 17, weight: .semibold))
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color("Gold"))
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                }
                .padding()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private var requestLocationButton: some View {
        Button(action: { locationManager.requestPermission() }) {
            HStack {
                Image(systemName: "location.circle.fill")
                Text("Enable Location Services")
                    .font(.custom("Lora-Regular", size: 17))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("Gold"))
            )
        }
    }
    
    private var deniedLocationView: some View {
        VStack(spacing: 16) {
            Text("Location access is required")
                .font(.custom("Lora-Regular", size: 17))
                .foregroundColor(Color.accent)
            
            Text("Please enable location access in Settings to continue")
                .font(.custom("Lora-Regular", size: 15))
                .foregroundColor(Color.accent.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button(action: openSettings) {
                Text("Open Settings")
                    .font(.custom("Lora-Regular", size: 17))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color("Gold"))
                    )
            }
        }
    }
    
    private var locationGrantedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(Color("Gold"))
            
            Text("Location access granted")
                .font(.custom("Lora-Regular", size: 17))
                .foregroundColor(Color.accent)
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func saveLocationAndContinue() {
        guard let userId = Auth.auth().currentUser?.uid,
              let location = locationManager.location else { return }
        
        isLoading = true
        
        let userData: [String: Any] = [
            "location": GeoPoint(latitude: location.coordinate.latitude,
                               longitude: location.coordinate.longitude),
            "setupProgress": SignupProgress.locationComplete.rawValue
        ]
        
        db.collection("users").document(userId).updateData(userData) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving location: \(error.localizedDescription)"
                showError = true
                return
            }
            
            withAnimation {
                appViewModel.updateProgress(.locationComplete)
                currentStep += 1
            }
        }
    }
}

#Preview {
    LocationPermissionView(isAuthenticated: .constant(false), currentStep: .constant(0))
        .environmentObject(AppViewModel())
} 
