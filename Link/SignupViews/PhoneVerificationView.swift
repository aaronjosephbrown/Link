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
    @State private var verificationCode = ""
    @State private var verificationID = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var isPhoneNumberFocused = false
    @State private var isShowingVerificationCode = false
    @Binding var isAuthenticated: Bool
    @Binding var currentStep: Int
    
    var body: some View {
        BackgroundView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color("Gold"))
                        .padding(.bottom, 8)
                        .symbolEffect(.bounce, options: .repeating)
                    Text("Lumé")
                        .font(.custom("GreatVibes-Regular", size: 50))
                        .foregroundColor(.accent)
                        .padding(.top)
                    
                    Text("Enter your phone number to get started")
                        .font(.custom("Lora-Regular", size: 19))
                        .foregroundColor(.accent)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Progress indicator
                SignupProgressView(currentStep: currentStep)
                
                // Phone number field
                VStack(alignment: .leading, spacing: 8) {
                    Text("PHONE NUMBER")
                        .font(.custom("Lora-Regular", size: 16))
                        .foregroundColor(.accent)
                    
                    HStack {
                        Image(systemName: "phone")
                            .foregroundColor(.accent)
                            .padding(.leading, 16)
                        
                        TextField("", text: $phoneNumber)
                            .textFieldStyle(PlainTextFieldStyle())
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .font(.custom("Lora-Regular", size: 18))
                            .foregroundColor(Color("AccentColor"))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isPhoneNumberFocused ? Color("Gold").opacity(0.3) : Color("Gold"), lineWidth: 2)
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
                            HStack {
                                Text("Continue")
                                    .font(.system(size: 17, weight: .semibold))
                                
                                if phoneNumber.count >= 10 {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(phoneNumber.count >= 10 ? Color("Gold") : Color.gray.opacity(0.3))
                            )
                            .animation(.easeInOut(duration: 0.2), value: phoneNumber.count >= 10)
                        }
                        .disabled(phoneNumber.count < 10 || isLoading)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .navigationDestination(isPresented: $isShowingVerificationCode) {
            VerificationCodeView(
                verificationCode: $verificationCode,
                phoneNumber: phoneNumber,
                verificationID: verificationID,
                isAuthenticated: $isAuthenticated,
                currentStep: $currentStep
            )
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
    @Binding var currentStep: Int
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var isCodeFocused = false
    
    var body: some View {
        BackgroundView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "message.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color("Gold"))
                        .padding(.bottom, 8)
                    
                    Text("Enter Verification Code")
                        .font(.custom("Lora-Regular", size: 28))
                        .padding(.top)
                        .foregroundColor(.accent)
                    
                    VStack(spacing: 4) {
                        Text("We've sent a 6-digit code to\n\(phoneNumber)")
                            .font(.custom("Lora-Regular", size: 15))
                            .foregroundColor(.accent)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(height: 40)
                }
                .padding(.top, 40)
                
                // Progress indicator
                SignupProgressView(currentStep: currentStep)
                
                // Code field
                VStack(alignment: .leading, spacing: 8) {
                    Text("VERIFICATION CODE")
                        .font(.custom("Lora-Regular", size: 19))
                        .foregroundColor(.accent)
                    
                    TextField("", text: $verificationCode)
                        .textFieldStyle(PlainTextFieldStyle())
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .textContentType(.oneTimeCode)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isCodeFocused ? Color("Gold").opacity(0.3) : Color("Gold"), lineWidth: 2)
                        )
                        .onTapGesture { isCodeFocused = true }
                        .onSubmit { isCodeFocused = false }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Button(action: resendCode) {
                    Text("Resend Code")
                        .foregroundColor(.accent)
                        .font(.custom("Lora-Regular", size: 17))
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
                                .font(.custom("Lora-Regular", size: 17))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(verificationCode.count == 6 ? Color("Gold") : Color.gray.opacity(0.3))
                                )
                                .animation(.easeInOut(duration: 0.2), value: verificationCode.count == 6)
                        }
                        .disabled(verificationCode.count != 6 || isLoading)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding()
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
            currentStep = 1
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
        PhoneVerificationView(
            isAuthenticated: .constant(false),
            currentStep: .constant(0)
        )
    }
}

#Preview("Verification Code") {
    VerificationCodeView(
        verificationCode: .constant(""),
        phoneNumber: "123-456-7890",
        verificationID: "sample-id",
        isAuthenticated: .constant(false),
        currentStep: .constant(0)
    )
}

