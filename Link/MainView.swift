//
//  MainView.swift
//  Link
//
//  Created by Aaron Brown on 3/12/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MainView: View {
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var userName = ""
    @Binding var isAuthenticated: Bool
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Welcome, \(userName)!")
                    .font(.title)
                    .padding()
                
                Spacer()
                
                Button(action: signOut) {
                    Text("Sign Out")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Home")
            .navigationBarBackButtonHidden(true)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadUserProfile()
            }
        }
    }
    
    private func loadUserProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                errorMessage = "Error loading profile: \(error.localizedDescription)"
                showError = true
                return
            }
            
            if let document = document, document.exists,
               let firstName = document.data()?["firstName"] as? String {
                userName = firstName
            }
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
        } catch let signOutError as NSError {
            errorMessage = "Error signing out: \(signOutError.localizedDescription)"
            showError = true
        }
    }
}

#Preview {
    MainView(isAuthenticated: .constant(true))
} 