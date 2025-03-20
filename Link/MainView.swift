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
    @State private var selectedTab = 0
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
                            .environment(\.symbolVariants, selectedTab == 0 ? .fill : .none)
                    }
                    .tag(0)
                
                Text("Discover")
                    .tabItem {
                        Image(systemName: "star")
                            .environment(\.symbolVariants, selectedTab == 1 ? .fill : .none)
                    }
                    .tag(1)
                
                Text("Likes")
                    .tabItem {
                        Image(systemName: "heart")
                            .environment(\.symbolVariants, selectedTab == 2 ? .fill : .none)
                    }
                    .tag(2)
                
                Text("Messages")
                    .tabItem {
                        Image(systemName: "bubble.left")
                            .environment(\.symbolVariants, selectedTab == 3 ? .fill : .none)
                    }
                    .tag(3)
                
                ProfileView(userName: $userName, isAuthenticated: $isAuthenticated)
                    .tabItem {
                        Image(systemName: "person.circle")
                            .environment(\.symbolVariants, selectedTab == 4 ? .fill : .none)
                    }
                    .tag(4)
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