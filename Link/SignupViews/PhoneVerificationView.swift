//
//  PhoneVerificationView.swift
//  Link
//
//  Created by Aaron Brown on 3/13/25.
//

import SwiftUI
import FirebaseAuth

struct PhoneVerificationView: View {
    @State private var phoneNumber = ""
    @State private var isShowingVerificationCode = false
    @State private var verificationCode = ""
    @State private var verificationID = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var isPhoneNumberFocused = false
    @Binding var isAuthenticated: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "phone.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.bottom, 8)
                
                Text("Welcome to Link")
                    .font(.system(size: 28, weight: .bold))
                    .padding(.top)
                
                Text("Enter your phone number to get started")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            // Progress indicator
            SignupProgressView(currentStep: 0, totalSteps: 17)
            
            // Phone number field
            VStack(alignment: .leading, spacing: 8) {
                Text("PHONE NUMBER")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("+1")
                        .foregroundColor(.secondary)
                        .padding(.leading, 16)
                    
                    TextField("", text: $phoneNumber)
                        .textFieldStyle(PlainTextFieldStyle())
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isPhoneNumberFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                        .background(Color(.systemBackground))
                )
                .onTapGesture { isPhoneNumberFocused = true }
                .onSubmit { isPhoneNumberFocused = false }
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
                    Button(action: sendVerificationCode) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(phoneNumber.count >= 10 ? Color.blue : Color.gray.opacity(0.3))
                            )
                            .animation(.easeInOut(duration: 0.2), value: phoneNumber.count >= 10)
                    }
                    .disabled(phoneNumber.count < 10 || isLoading)
                }
                
                Text("Step 1 of 17 in setting up your profile")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .padding()
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingVerificationCode) {
            VerificationCodeView(verificationCode: $verificationCode, 
                               phoneNumber: phoneNumber, 
                               verificationID: verificationID,
                               isAuthenticated: $isAuthenticated)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func sendVerificationCode() {
        isLoading = true
        let formattedNumber = "+1\(phoneNumber.replacingOccurrences(of: " ", with: ""))"
        
        PhoneAuthProvider.provider()
            .verifyPhoneNumber(formattedNumber, uiDelegate: nil) { verificationId, error in
            isLoading = false
            
            if let error = error {
                errorMessage = error.localizedDescription
                showError = true
                return
            }
            
            if let verificationId = verificationId {
                self.verificationID = verificationId
                UserDefaults.standard.set(verificationId, forKey: "authVerificationID")
                isShowingVerificationCode = true
            }
        }
    }
}

struct VerificationCodeView: View {
    @Binding var verificationCode: String
    let phoneNumber: String
    let verificationID: String
    @Binding var isAuthenticated: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var isCodeFocused = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "message.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .padding(.bottom, 8)
                    
                    Text("Enter Verification Code")
                        .font(.system(size: 28, weight: .bold))
                        .padding(.top)
                    
                    Text("We've sent a 6-digit code to\n\(phoneNumber)")
                        .font(.system(size: 17))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Progress indicator
                SignupProgressView(currentStep: 0, totalSteps: 17)
                
                // Code field
                VStack(alignment: .leading, spacing: 8) {
                    Text("VERIFICATION CODE")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("", text: $verificationCode)
                        .textFieldStyle(PlainTextFieldStyle())
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .textContentType(.oneTimeCode)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isCodeFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                .background(Color(.systemBackground))
                        )
                        .onTapGesture { isCodeFocused = true }
                        .onSubmit { isCodeFocused = false }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Button(action: resendCode) {
                    Text("Resend Code")
                        .foregroundColor(.blue)
                        .font(.system(size: 15))
                }
                .padding(.top)
                .disabled(isLoading)
                
                Spacer()
                
                // Verify button
                VStack(spacing: 16) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.2)
                    } else {
                        Button(action: verifyCode) {
                            Text("Verify")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(verificationCode.count == 6 ? Color.blue : Color.gray.opacity(0.3))
                                )
                                .animation(.easeInOut(duration: 0.2), value: verificationCode.count == 6)
                        }
                        .disabled(verificationCode.count != 6 || isLoading)
                    }
                    
                    Text("Step 1 of 17 in setting up your profile")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding()
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func verifyCode() {
        isLoading = true
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )
        
        Auth.auth().signIn(with: credential) { result, error in
            isLoading = false
            
            if let error = error {
                errorMessage = error.localizedDescription
                showError = true
                return
            }
            
            // Successfully signed in
            isAuthenticated = true
            dismiss()
        }
    }
    
    private func resendCode() {
        isLoading = true
        let formattedNumber = "+1\(phoneNumber.replacingOccurrences(of: " ", with: ""))"
        
        PhoneAuthProvider.provider().verifyPhoneNumber(formattedNumber, uiDelegate: nil) { verificationId, error in
            isLoading = false
            
            if let error = error {
                errorMessage = error.localizedDescription
                showError = true
                return
            }
            
            // Clear the verification code field
            verificationCode = ""
        }
    }
}

#Preview("Phone Verification") {
    NavigationView {
        PhoneVerificationView(isAuthenticated: .constant(false))
    }
}

#Preview("Verification Code") {
    VerificationCodeView(
        verificationCode: .constant(""),
        phoneNumber: "123-456-7890",
        verificationID: "sample-id",
        isAuthenticated: .constant(false)
    )
}

