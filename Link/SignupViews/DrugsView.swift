import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct DrugsView: View {
    @Binding var isAuthenticated: Bool
    @Binding var currentStep: Int
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedOption: String?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var navigateToProfilePictures = false
    
    private let db = Firestore.firestore()
    
    private let drugOptions = [
        "Never",
        "Rarely",
        "Sometimes",
        "Often",
        "Everyday",
        "Prefer not to say"
    ]
    
    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "pills.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color("Gold"))
                            .symbolEffect(.bounce, options: .repeating)
                        
                        Text("Drug Use")
                            .font(.custom("Lora-Regular", size: 24))
                            .foregroundColor(Color.accent)
                        
                        Text("This helps us find better matches for you")
                            .font(.custom("Lora-Regular", size: 16))
                            .foregroundColor(Color.accent.opacity(0.7))
                    }
                    .padding(.top, 40)
                    
                    // Progress indicator
                    SignupProgressView(currentStep: currentStep, totalSteps: 17)
                    
                    // Options
                    VStack(spacing: 16) {
                        ForEach(drugOptions, id: \.self) { option in
                            Button(action: { selectedOption = option }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(option)
                                            .font(.custom("Lora-Regular", size: 17))
                                            .foregroundColor(selectedOption == option ? .white : Color.accent)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedOption == option {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedOption == option ? Color("Gold") : Color("Gold").opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedOption == option ? Color("Gold") : Color("Gold").opacity(0.3), lineWidth: 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Complete Setup button
                    VStack(spacing: 16) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(1.2)
                        } else {
                            Button(action: saveAndContinue) {
                                HStack {
                                    Text("Complete Setup")
                                        .font(.system(size: 17, weight: .semibold))
                                    
                                    if selectedOption != nil {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedOption != nil ? Color("Gold") : Color.gray.opacity(0.3))
                                )
                                .animation(.easeInOut(duration: 0.2), value: selectedOption)
                            }
                            .disabled(selectedOption == nil)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
                .padding()
                .navigationBarBackButtonHidden(true)
                .alert("Error", isPresented: $showError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(errorMessage)
                }
            }
        }
        .navigationDestination(isPresented: $navigateToProfilePictures) {
            ProfilePicturesView(isAuthenticated: $isAuthenticated)
        }
    }
    
    private func saveAndContinue() {
        guard let option = selectedOption else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        let userData: [String: Any] = [
            "drugUse": option,
            "setupProgress": SignupProgress.drugsComplete.rawValue
        ]
        
        db.collection("users").document(userId).updateData(userData) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving drug use information: \(error.localizedDescription)"
                showError = true
                return
            }
            
            withAnimation {
                appViewModel.updateProgress(.drugsComplete)
                currentStep = 17
                navigateToProfilePictures = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        DrugsView(
            isAuthenticated: .constant(false),
            currentStep: .constant(16)
        )
        .environmentObject(AppViewModel())
    }
    .preferredColorScheme(.light)
}

// Dark mode preview
#Preview("Dark Mode") {
    NavigationStack {
        DrugsView(
            isAuthenticated: .constant(false),
            currentStep: .constant(16)
        )
        .environmentObject(AppViewModel())
    }
    .preferredColorScheme(.dark)
} 
