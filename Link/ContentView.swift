//
//  ContentView.swift
//  Link
//
//  Created by Aaron Brown on 3/12/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ContentView: View {
    @State private var isAuthenticated = false
    @AppStorage("setupComplete") private var localSetupComplete = false
    @AppStorage("currentSignupProgress") private var currentSignupProgress = SignupProgress.initial.rawValue
    @State private var isLoading = true
    @State private var authStateHandle: AuthStateDidChangeListenerHandle?
    @StateObject private var appViewModel = AppViewModel()
    
    private let db = Firestore.firestore()
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else if isAuthenticated {
                if localSetupComplete {
                    MainView(isAuthenticated: $isAuthenticated)
                        .environmentObject(appViewModel)
                } else {
                    ProfileSetupFlowView(isAuthenticated: $isAuthenticated)
                        .environmentObject(appViewModel)
                }
            } else {
                NavigationView {
                    PhoneVerificationView(isAuthenticated: $isAuthenticated)
                }
            }
        }
        .onAppear {
            // Check for existing auth session
            if Auth.auth().currentUser != nil {
                isAuthenticated = true
                checkSetupProgress()
            } else {
                // Reset progress if not authenticated
                currentSignupProgress = SignupProgress.initial.rawValue
                localSetupComplete = false
                isLoading = false
            }
            
            // Listen for auth state changes
            authStateHandle = Auth.auth().addStateDidChangeListener { auth, user in
                isAuthenticated = user != nil
                if user != nil {
                    checkSetupProgress()
                } else {
                    // Reset progress on logout
                    currentSignupProgress = SignupProgress.initial.rawValue
                    localSetupComplete = false
                    isLoading = false
                }
            }
        }
        .onDisappear {
            if let handle = authStateHandle {
                Auth.auth().removeStateDidChangeListener(handle)
            }
        }
    }
    
    private func checkSetupProgress() {
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error checking setup progress: \(error.localizedDescription)")
                // Fall back to local storage if Firestore fails
                localSetupComplete = SignupProgress(rawValue: currentSignupProgress) == .complete
                isLoading = false
                return
            }
            
            if let document = document, document.exists,
               let progress = document.data()?["setupProgress"] as? String {
                // Update both local storage and app state
                currentSignupProgress = progress
                localSetupComplete = progress == SignupProgress.complete.rawValue
                appViewModel.updateProgress(SignupProgress(rawValue: progress) ?? .initial)
            } else {
                // If no document exists, initialize with current local progress
                let progress = SignupProgress(rawValue: currentSignupProgress) ?? .initial
                appViewModel.updateProgress(progress)
            }
            isLoading = false
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
}
