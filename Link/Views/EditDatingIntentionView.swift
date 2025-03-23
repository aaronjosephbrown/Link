import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditDatingIntentionView: View {
    @Binding var isAuthenticated: Bool
    @Binding var selectedTab: String
    @State private var selectedIntention: String?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    private let db = Firestore.firestore()
    
    private let intentionOptions = [
        "Long-term relationship",
        "Marriage",
        "Casual dating",
        "Friendship first",
        "Still figuring it out"
    ]
    
    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color("Gold"))
                            .padding(.bottom, 8)
                        Text("Edit Dating Intention")
                            .font(.custom("Lora-Regular", size: 19))
                            .foregroundColor(Color.accent)
                    }
                    .padding(.top, 40)
                    
                    // Intention options
                    VStack(spacing: 12) {
                        ForEach(intentionOptions, id: \.self) { option in
                            Button(action: { selectedIntention = option }) {
                                HStack {
                                    Text(option)
                                        .font(.custom("Lora-Regular", size: 17))
                                        .foregroundColor(Color.accent)
                                    Spacer()
                                    if selectedIntention == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color("Gold"))
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedIntention == option ? Color("Gold") : Color("Gold").opacity(0.3), lineWidth: 2)
                                )
                            }
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
                                            .fill(selectedIntention != nil ? Color("Gold") : Color.gray.opacity(0.3))
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: selectedIntention != nil)
                            }
                            .disabled(selectedIntention == nil)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
                .padding()
                .navigationBarBackButtonHidden(false)
                .navigationBarItems(leading: 
                    Button(action: {
                        selectedTab = "Profile"
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .foregroundColor(Color("Gold"))
                            Text("Back")
                                .foregroundColor(Color("Gold"))
                        }
                    }
                )
                .alert("Error", isPresented: $showError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(errorMessage)
                }
                .onAppear {
                    loadUserIntention()
                }
            }
        }
    }
    
    private func loadUserIntention() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error loading dating intention: \(error.localizedDescription)")
                return
            }
            
            if let document = document,
               let intention = document.data()?["datingIntention"] as? String {
                DispatchQueue.main.async {
                    selectedIntention = intention
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let intention = selectedIntention else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        db.collection("users").document(userId).updateData([
            "datingIntention": intention
        ]) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving dating intention: \(error.localizedDescription)"
                showError = true
                return
            }
            
            selectedTab = "Profile"
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        EditDatingIntentionView(isAuthenticated: .constant(true), selectedTab: .constant("Profile"))
    }
} 