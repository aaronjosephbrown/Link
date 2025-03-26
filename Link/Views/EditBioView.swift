import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditBioView: View {
    @Binding var isAuthenticated: Bool
    @Binding var selectedTab: String
    @State private var bio: String = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    private let db = Firestore.firestore()
    
    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        HStack {
                            Spacer()
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundColor(Color("Gold"))
                            }
                        }
                        Image(systemName: "text.quote")
                            .font(.system(size: 60))
                            .foregroundColor(Color("Gold"))
                            .padding(.bottom, 8)
                        Text("Edit Bio")
                            .font(.custom("Lora-Regular", size: 19))
                            .foregroundColor(Color.accent)
                    }
                    .padding(.top, 40)
                    
                    // Bio text editor
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tell us about yourself")
                            .font(.custom("Lora-Regular", size: 17))
                            .foregroundColor(Color.accent)
                        
                        ZStack(alignment: .topLeading) {
                            if bio.isEmpty {
                                Text("Write something about yourself...")
                                    .foregroundColor(.gray)
                                    .padding(.leading, 12)
                                    .padding(.top, 16)
                            }
                            TextEditor(text: $bio)
                                .frame(height: 200)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                                )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Save button
                    VStack(spacing: 16) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(1.2)
                        } else {
                            Button(action: saveChanges) {
                                Text("Save Changes")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(!bio.isEmpty ? Color("Gold") : Color.gray.opacity(0.3))
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: !bio.isEmpty)
                            }
                            .disabled(bio.isEmpty)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadUserBio()
            }
        }
        .interactiveDismissDisabled()
    }
    
    private func loadUserBio() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error loading bio: \(error.localizedDescription)")
                return
            }
            
            if let document = document {
                DispatchQueue.main.async {
                    bio = document.data()?["bio"] as? String ?? ""
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        // First save the bio
        db.collection("users").document(userId).updateData([
            "bio": bio
        ]) { error in
            if let error = error {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = "Error saving bio: \(error.localizedDescription)"
                    showError = true
                }
                return
            }
            
            // Only dismiss after successful save
            DispatchQueue.main.async {
                isLoading = false
                selectedTab = "Profile"
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditBioView(isAuthenticated: .constant(true), selectedTab: .constant("Profile"))
    }
} 