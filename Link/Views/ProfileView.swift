import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct ProfileView: View {
    @Binding var userName: String
    @Binding var isAuthenticated: Bool
    @State private var profileCompletion: Double = 0.44
    @State private var profileImageUrl: String?
    @State private var isLoadingImage = false
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Profile Header
                    HStack {
                        Text("Lumé")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color.accent)
                        Spacer()
                        Button(action: {}) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.title2)
                                .foregroundColor(Color("Gold"))
                        }
                        Button(action: {}) {
                            Image(systemName: "gearshape")
                                .font(.title2)
                                .foregroundColor(Color("Gold"))
                        }
                    }
                    .padding(.horizontal)
                    
                    // Profile Picture with Completion Ring
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: profileCompletion)
                            .stroke(Color("Gold"), lineWidth: 8)
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                        
                        if isLoadingImage {
                            ProgressView()
                                .frame(width: 110, height: 110)
                        } else if let imageUrl = profileImageUrl {
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 110, height: 110)
                                    .clipShape(Circle())
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 110, height: 110)
                            }
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 110, height: 110)
                        }
                        
                        Text("\(Int(profileCompletion * 100))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color.accent)
                            .offset(y: 70)
                    }
                    
                    // Name and Verification
                    HStack {
                        Text(userName)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.accent)
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(Color("Gold"))
                    }
                    
                    Text("Incomplete profile")
                        .foregroundColor(Color.accent.opacity(0.7))
                    
                    // Navigation Tabs
                    HStack(spacing: 0) {
                        NavigationLink(destination: EmptyView()) {
                            Text("Get more")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .foregroundColor(Color.accent)
                        }
                        
                        NavigationLink(destination: EmptyView()) {
                            Text("Safety")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .foregroundColor(Color.accent)
                        }
                        
                        NavigationLink(destination: EmptyView()) {
                            Text("My Lumé")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .foregroundColor(Color.accent)
                        }
                    }
                    .background(Color("Gold").opacity(0.1))
                    
                    // Premium Promotion
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Premium")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Get seen sooner and go on 3x as many dates")
                            .foregroundColor(.white)
                        
                        Button(action: {}) {
                            Text("Upgrade")
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .frame(width: 120)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .cornerRadius(20)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("Gold"))
                    )
                    .padding(.horizontal)
                    
                    // Boost Section
                    HStack {
                        Circle()
                            .fill(Color("Gold"))
                            .frame(width: 50, height: 50)
                            .overlay(
                                ZStack {
                                    Image(systemName: "bolt.fill")
                                        .foregroundColor(.white)
                                    Text("0")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .offset(x: 15, y: -15)
                                }
                            )
                        
                        VStack(alignment: .leading) {
                            Text("Boost")
                                .font(.headline)
                                .foregroundColor(Color.accent)
                            Text("Get seen by 11X more people")
                                .font(.subheadline)
                                .foregroundColor(Color.accent.opacity(0.7))
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color("Gold").opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Roses Section
                    HStack {
                        Circle()
                            .fill(Color("Gold"))
                            .frame(width: 50, height: 50)
                            .overlay(
                                ZStack {
                                    Image(systemName: "rosette")
                                        .foregroundColor(.white)
                                    Text("0")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .offset(x: 15, y: -15)
                                }
                            )
                        
                        VStack(alignment: .leading) {
                            Text("Roses")
                                .font(.headline)
                                .foregroundColor(Color.accent)
                            Text("2x as likely to lead to a date")
                                .font(.subheadline)
                                .foregroundColor(Color.accent.opacity(0.7))
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color("Gold").opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Button(action: signOut) {
                        Text("Sign Out")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("Gold"))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .onAppear {
                loadProfilePicture()
            }
        }
    }
    
    private func loadProfilePicture() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoadingImage = true
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error loading profile: \(error.localizedDescription)")
                isLoadingImage = false
                return
            }
            
            if let document = document,
               let profilePictures = document.data()?["profilePictures"] as? [String],
               let firstPicture = profilePictures.first {
                profileImageUrl = firstPicture
            }
            isLoadingImage = false
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ProfileView(userName: .constant("Aaron"), isAuthenticated: .constant(true))
} 
