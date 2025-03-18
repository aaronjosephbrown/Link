import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EmailCollectionView: View {
    @Binding var isAuthenticated: Bool
    @Binding var currentStep: Int
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var email = ""
    @State private var verificationCode = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showVerificationField = false
    @State private var isEmailFocused = false
    @State private var isCodeFocused = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        BackgroundView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color("Gold"))
                        .padding(.bottom, 8)
                    
                    Text("Email Verification")
                        .font(.custom("Lora-Regular", size: 19))
                        .foregroundColor(.accent)
                    
                    Text(showVerificationField ? "Enter the verification code sent to your email" : "Please verify your email to continue")
                        .font(.custom("Lora-Regular", size: 19))
                        .foregroundColor(Color.accent)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Progress indicator
                SignupProgressView(currentStep: currentStep, totalSteps: 17)
                
                // Form fields
                VStack(spacing: 20) {
                    if !showVerificationField {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("EMAIL ADDRESS")
                                .font(.custom("Lora-Regular", size: 19))
                                .foregroundColor(Color.accent)
                            
                            TextField("", text: $email)
                                .textFieldStyle(PlainTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding()
                                .foregroundColor(Color("AccentColor"))
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isEmailFocused ? Color("Gold").opacity(0.3) : Color("Gold"), lineWidth: 2)
                                )
                                .onTapGesture { isEmailFocused = true }
                                .onSubmit { isEmailFocused = false }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("VERIFICATION CODE")
                                .font(.custom("Lora-Regular", size: 19))
                                .foregroundColor(Color.accent)
                                .symbolEffect(.bounce, options: .repeating)
                            
                            TextField("", text: $verificationCode)
                                .textFieldStyle(PlainTextFieldStyle())
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .padding()
                                .foregroundColor(Color("AccentColor"))
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isCodeFocused ? Color("Gold").opacity(0.3) : Color("Gold"), lineWidth: 2)
                                )
                                .onTapGesture { isCodeFocused = true }
                                .onSubmit { isCodeFocused = false }
                                .onChange(of: verificationCode) { _, newValue in
                                    if newValue.count > 6 {
                                        verificationCode = String(newValue.prefix(6))
                                    }
                                }
                        }
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
                        Button(action: showVerificationField ? verifyCode : sendVerificationCode) {
                            HStack {
                                Text(showVerificationField ? "Verify" : "Send Code")
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
        }
    }
    
    private var formIsValid: Bool {
        if showVerificationField {
            return verificationCode.count == 6
        } else {
            return email.contains("@") && email.contains(".")
        }
    }
    
    private func sendVerificationCode() {
        // TODO: Implement actual email verification
        // For now, we'll simulate sending a code
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            showVerificationField = true
        }
    }
    
    private func verifyCode() {
        // TODO: Implement actual code verification
        // For now, we'll simulate verification
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        let userData: [String: Any] = [
            "email": email,
            "setupProgress": SignupProgress.emailVerified.rawValue
        ]
        
        db.collection("users").document(userId).updateData(userData) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving email: \(error.localizedDescription)"
                showError = true
                return
            }
            
            appViewModel.updateProgress(.emailVerified)
            currentStep = 2
        }
    }
}

#Preview("Email Collection") {
    NavigationView {
        EmailCollectionView(
            isAuthenticated: .constant(true),
            currentStep: .constant(1)
        )
        .environmentObject(AppViewModel())
    }
} 
