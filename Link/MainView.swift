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
    @State private var selectedTab = "Home"
    @Binding var isAuthenticated: Bool
    
    private let db = Firestore.firestore()
    
    init(isAuthenticated: Binding<Bool>) {
        self._isAuthenticated = isAuthenticated
        
        // Configure UITabBar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        
        // Make it translucent
        appearance.backgroundEffect = UIBlurEffect(style: .light)
        appearance.backgroundColor = .white.withAlphaComponent(0.5)
        
        // Configure shadow to make it stand out slightly
        appearance.shadowColor = .black.withAlphaComponent(0.3)
        
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().standardAppearance = appearance
    }
    
    var body: some View {
        BackgroundView {
            TabView(selection: $selectedTab) {
                Text("Home")
                    .tabItem {
                        Image(systemName: "l.square")
                            .environment(\.symbolVariants, selectedTab == "Home" ? .fill : .none)
                    }
                    .tag("Home")
                
                Text("Discover")
                    .tabItem {
                        Image(systemName: "star")
                            .environment(\.symbolVariants, selectedTab == "Discover" ? .fill : .none)
                    }
                    .tag("Discover")
                
                Text("Likes")
                    .tabItem {
                        Image(systemName: "heart")
                            .environment(\.symbolVariants, selectedTab == "Likes" ? .fill : .none)
                    }
                    .tag("Likes")
                
                Text("Messages")
                    .tabItem {
                        Image(systemName: "bubble.left")
                            .environment(\.symbolVariants, selectedTab == "Messages" ? .fill : .none)
                    }
                    .tag("Messages")
                
                ProfileView(userName: $userName, isAuthenticated: $isAuthenticated, selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "person.circle")
                            .environment(\.symbolVariants, selectedTab == "Profile" ? .fill : .none)
                    }
                    .tag("Profile")
            }
            .tint(Color("Gold"))
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
}

#Preview {
    MainView(isAuthenticated: .constant(true))
} 
