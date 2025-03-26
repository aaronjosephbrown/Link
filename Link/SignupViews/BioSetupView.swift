import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct BioSetupView: View {
    @Binding var isAuthenticated: Bool
    @Binding var selectedTab: String
    @State private var bio: String = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appViewModel: AppViewModel
    
    private let db = Firestore.firestore()
    
    var body: some View {
        BackgroundView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "text.quote")
                        .font(.system(size: 60))
                        .foregroundColor(Color("Gold"))
                        .padding(.bottom, 8)
                    Text("Tell us about yourself")
                        .font(.custom("Lora-Regular", size: 19))
                        .foregroundColor(Color.accent)
                }
                .padding(.top, 40)
                
                // Bio text editor
                VStack(alignment: .leading, spacing: 8) {
                    Text("Write a brief bio to help others get to know you")
                        .font(.custom("Lora-Regular", size: 17))
                        .foregroundColor(Color.accent)
                    
                    TextEditor(text: $bio)
                        .frame(height: 200)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                        )
                        .overlay(
                            Group {
                                if bio.isEmpty {
                                    Text("Write something about yourself...")
                                        .foregroundColor(.gray)
                                        .padding(.leading, 12)
                                        .padding(.top, 16)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Navigation Buttons
                VStack(spacing: 16) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.2)
                    } else {
                        Button(action: saveBio) {
                            Text("Continue")
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
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveBio() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        db.collection("users").document(userId).updateData([
            "bio": bio
        ]) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving bio: \(error.localizedDescription)"
                showError = true
                return
            }
            
            // Update signup progress
            appViewModel.updateProgress(.bioComplete)
            
            selectedTab = "Profile"
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        BioSetupView(isAuthenticated: .constant(true), selectedTab: .constant("Profile"))
            .environmentObject(AppViewModel())
    }
} 