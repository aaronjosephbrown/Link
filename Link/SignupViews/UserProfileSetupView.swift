import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserProfileSetupView: View {
    @Binding var isAuthenticated: Bool
    @Binding var currentStep: Int
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isFirstNameFocused = false
    @State private var isLastNameFocused = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.bottom, 8)
                
                Text("Welcome to Link")
                    .font(.system(size: 28, weight: .bold))
                    .padding(.top)
                
                Text("Let's set up your profile")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            // Progress indicator
            SignupProgressView(currentStep: 0, totalSteps: 17)
            
            // Form fields
            VStack(spacing: 20) {
                // First Name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("FIRST NAME")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("", text: $firstName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isFirstNameFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                .background(Color(.systemBackground))
                        )
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                        .onTapGesture { isFirstNameFocused = true }
                        .onSubmit { isFirstNameFocused = false }
                }
                
                // Last Name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("LAST NAME")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("", text: $lastName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isLastNameFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                .background(Color(.systemBackground))
                        )
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                        .onTapGesture { isLastNameFocused = true }
                        .onSubmit { isLastNameFocused = false }
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            Spacer()
            
            // Continue button
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                } else {
                    Button(action: saveNameAndContinue) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(formIsValid ? Color.blue : Color.gray.opacity(0.3))
                            )
                            .animation(.easeInOut(duration: 0.2), value: formIsValid)
                    }
                    .disabled(!formIsValid)
                }
                
                Text("This is step 1 of 5 in setting up your profile")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .padding()
        .background(Color(.systemBackground))
        .navigationBarBackButtonHidden(true)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            checkExistingProfile()
        }
    }
    
    private var formIsValid: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func checkExistingProfile() {
        appViewModel.checkCurrentProgress { progress in
            switch progress {
            case .nameEntered:
                currentStep = 1
            case .emailVerified:
                currentStep = 2
            case .dobVerified:
                currentStep = 3
            case .genderComplete:
                currentStep = 4
            case .sexualityComplete:
                currentStep = 5
            case .sexualityPreferenceComplete:
                currentStep = 6
            case .heightComplete:
                currentStep = 7
            case .datingIntentionComplete:
                currentStep = 8
            case .childrenComplete:
                currentStep = 9
            case .familyPlansComplete:
                currentStep = 10
            case .educationComplete:
                currentStep = 11
            case .religionComplete:
                currentStep = 12
            case .ethnicityComplete:
                currentStep = 13
            case .drinkingComplete:
                currentStep = 14
            case .smokingComplete:
                currentStep = 15
            case .politicsComplete:
                currentStep = 16
            case .complete:
                isAuthenticated = true
            case .initial:
                break
            }
        }
    }
    
    private func saveNameAndContinue() {
        guard formIsValid else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        let userData: [String: Any] = [
            "firstName": firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            "lastName": lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            "setupProgress": SignupProgress.nameEntered.rawValue
        ]
        
        db.collection("users").document(userId).setData(userData, merge: true) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving profile: \(error.localizedDescription)"
                showError = true
                return
            }
            
            withAnimation {
                appViewModel.updateProgress(.nameEntered)
                currentStep = 1
            }
        }
    }
}

#Preview {
    NavigationStack {
        UserProfileSetupView(
            isAuthenticated: .constant(false),
            currentStep: .constant(0)
        )
        .environmentObject(AppViewModel())
    }
    .preferredColorScheme(.light)
}

// Dark mode preview
#Preview("Dark Mode") {
    NavigationStack {
        UserProfileSetupView(
            isAuthenticated: .constant(false),
            currentStep: .constant(0)
        )
        .environmentObject(AppViewModel())
    }
    .preferredColorScheme(.dark)
} 