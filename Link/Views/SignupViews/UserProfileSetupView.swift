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
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color("Gold"))
                            .padding(.bottom, 8)
                        
                        Text("Let's set up your profile")
                            .font(.custom("Lora-Regular", size: 19))
                            .foregroundColor(Color.accent)
                    }
                    .padding(.top, 40)
                    
                    // Progress indicator
                    SignupProgressView(currentStep: currentStep)
                    
                    // Form fields
                    VStack(spacing: 20) {
                        // First Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("FIRST NAME")
                                .font(.custom("Lora-Regular", size: 17))
                                .foregroundColor(Color.accent)
                            
                            TextField("", text: $firstName)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.custom("Lora-Regular", size: 17))
                                .foregroundColor(Color("AccentColor"))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isFirstNameFocused ? Color("Gold").opacity(0.3) : Color("Gold"), lineWidth: 2)
                                )
                                .autocapitalization(.words)
                                .disableAutocorrection(true)
                                .onTapGesture { isFirstNameFocused = true }
                                .onSubmit { isFirstNameFocused = false }
                        }
                        
                        // Last Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("LAST NAME")
                                .foregroundColor(Color.accent)
                            
                            TextField("", text: $lastName)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .foregroundColor(Color("AccentColor"))
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isLastNameFocused ? Color("Gold").opacity(0.3) : Color("Gold"), lineWidth: 2)
                                    
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
                                HStack {
                                    Text("Continue")
                                        .font(.system(size: 17, weight: .semibold))
                                    
                                    if formIsValid {
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(formIsValid ? Color("Gold") : Color.gray.opacity(0.3))
                                )
                                .animation(.easeInOut(duration: 0.2), value: formIsValid)
                            }
                            .disabled(!formIsValid)
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
                .onAppear {
                    // Update current step based on progress
                    currentStep = appViewModel.getCurrentStep()
                }
            }
        }
    }
    
    private var formIsValid: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
