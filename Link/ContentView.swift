//
//  ContentView.swift
//  Link
//
//  Created by Aaron Brown on 3/12/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

enum AppState {
    case loading
    case unauthenticated
    case authenticated
    case setupComplete
}

struct ContentView: View {
    @State private var appState: AppState = .loading
    @AppStorage("setupComplete") private var localSetupComplete = false
    @AppStorage("currentSignupProgress") private var currentSignupProgress = SignupProgress.initial.rawValue
    @State private var currentStep = 0
    @State private var authStateHandler: AuthStateDidChangeListenerHandle?
    @StateObject private var appViewModel = AppViewModel()
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            Group {
                switch appState {
                case .loading:
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                case .unauthenticated:
                    PhoneVerificationView(isAuthenticated: .constant(false), currentStep: $currentStep)
                case .authenticated:
                    ProfileSetupFlowView(isAuthenticated: .constant(true))
                        .environmentObject(appViewModel)
                case .setupComplete:
                    MainView(isAuthenticated: .constant(true))
                        .environmentObject(appViewModel)
                }
            }
            .onAppear {
                setupAuthStateListener()
            }
            .onDisappear {
                if let handle = authStateHandler {
                    Auth.auth().removeStateDidChangeListener(handle)
                }
            }
        }
    }
    
    private func setupAuthStateListener() {
        // Set initial state to loading
        appState = .loading
        
        // Check initial auth state
        if let user = Auth.auth().currentUser {
            print("Found cached user, checking Firestore status...")
            handleAuthenticatedUser(user)
        } else {
            print("No cached user found, setting unauthenticated state")
            appState = .unauthenticated
        }
        
        // Listen for auth state changes
        authStateHandler = Auth.auth().addStateDidChangeListener { _, user in
            if let user = user {
                print("Auth state changed: user signed in")
                self.handleAuthenticatedUser(user)
            } else {
                print("Auth state changed: user signed out")
                self.handleUnauthenticatedUser()
            }
        }
    }
    
    private func handleAuthenticatedUser(_ user: User) {
        // First check if user exists in Firestore
        checkUserStatus(userId: user.uid) { exists in
            if exists {
                // Then check their setup progress
                checkSetupProgress(userId: user.uid)
            } else {
                // User doesn't exist in Firestore, sign them out
                do {
                    try Auth.auth().signOut()
                    handleUnauthenticatedUser()
                } catch {
                    print("Error signing out user: \(error.localizedDescription)")
                    handleUnauthenticatedUser()
                }
            }
        }
    }
    
    private func handleUnauthenticatedUser() {
        clearUserData()
        appState = .unauthenticated
    }
    
    private func checkUserStatus(userId: String, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error checking user status: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // Only return true if document exists and is not disabled
            if let document = document, document.exists {
                if let isDisabled = document.data()?["isDisabled"] as? Bool, isDisabled {
                    completion(false)
                } else {
                    completion(true)
                }
            } else {
                // Document doesn't exist, user should be signed out
                completion(false)
            }
        }
    }
    
    private func checkSetupProgress(userId: String) {
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error checking setup progress: \(error.localizedDescription)")
                // Fall back to local storage
                appState = SignupProgress(rawValue: currentSignupProgress) == .complete ? .setupComplete : .authenticated
                return
            }
            
            if let document = document, document.exists,
               let progress = document.data()?["setupProgress"] as? String {
                // Update local storage and app state
                currentSignupProgress = progress
                localSetupComplete = progress == SignupProgress.complete.rawValue
                appViewModel.updateProgress(SignupProgress(rawValue: progress) ?? .initial)
                currentStep = appViewModel.getCurrentStep()
                
                // Set appropriate app state
                appState = progress == SignupProgress.complete.rawValue ? .setupComplete : .authenticated
            } else {
                // Initialize new user
                let progress = SignupProgress(rawValue: currentSignupProgress) ?? .initial
                appViewModel.updateProgress(progress)
                currentStep = 1
                appState = .authenticated
            }
        }
    }
    
    private func clearUserData() {
        // Clear AppStorage values
        UserDefaults.standard.removeObject(forKey: "setupComplete")
        UserDefaults.standard.removeObject(forKey: "currentSignupProgress")
        
        // Reset local state
        localSetupComplete = false
        currentSignupProgress = SignupProgress.initial.rawValue
        currentStep = 0
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
}
