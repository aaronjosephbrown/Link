import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HeightSelectionView: View {
    @Binding var isAuthenticated: Bool
    @Binding var currentStep: Int
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var feet: Int = 5
    @State private var inches: Int = 8
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("What's your height?")
                .font(.title)
                .padding(.top)
            
            Text("Select your height")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            SignupProgressView(currentStep: 6, totalSteps: 17)
                .padding(.vertical, 20)
            
            HStack(spacing: 20) {
                Picker("Feet", selection: $feet) {
                    ForEach(4...7, id: \.self) { foot in
                        Text("\(foot) ft").tag(foot)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 100)
                .clipped()
                
                Picker("Inches", selection: $inches) {
                    ForEach(0...11, id: \.self) { inch in
                        Text("\(inch) in").tag(inch)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 100)
                .clipped()
            }
            .padding()
            
            Text("Your height: \(feet)'\(inches)\"")
                .font(.headline)
                .padding(.top)
            
            Spacer()
            
            if isLoading {
                ProgressView()
            } else {
                Button(action: saveHeightAndContinue) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                        )
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveHeightAndContinue() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        let heightInInches = (feet * 12) + inches
        
        let userData: [String: Any] = [
            "heightInInches": heightInInches,
            "setupProgress": SignupProgress.heightComplete.rawValue
        ]
        
        db.collection("users").document(userId).updateData(userData) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving height: \(error.localizedDescription)"
                showError = true
                return
            }
            
            withAnimation {
                appViewModel.updateProgress(.heightComplete)
                currentStep = 7
            }
        }
    }
}

#Preview {
    NavigationView {
        HeightSelectionView(isAuthenticated: .constant(true), currentStep: .constant(0))
            .environmentObject(AppViewModel())
    }
} 