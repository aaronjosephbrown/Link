import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditDatingIntentionView: View {
    @Binding var isAuthenticated: Bool
    @Binding var selectedTab: String
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var datingIntention = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    var isProfileSetup: Bool = false
    
    private let intentions = ["Long-term relationship", "Short-term relationship", "Marriage", "Not sure yet", "Other"]
    private let db = Firestore.firestore()
    
    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        if !isProfileSetup {
                            HStack {
                                Spacer()
                                Button(action: { dismiss() }) {
                                    Image(systemName: "xmark")
                                        .font(.title2)
                                        .foregroundColor(Color("Gold"))
                                }
                            }
                        }
                        Image(systemName: "heart.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color("Gold"))
                            .padding(.bottom, 8)
                        Text("Edit Dating Intention")
                            .font(.custom("Lora-Regular", size: 19))
                            .foregroundColor(Color.accent)
                    }
                    .padding(.top, 40)
                    
                    // Dating intention options
                    VStack(spacing: 12) {
                        ForEach(intentions, id: \.self) { option in
                            Button(action: { datingIntention = option }) {
                                HStack {
                                    Text(option)
                                        .font(.custom("Lora-Regular", size: 17))
                                        .foregroundColor(Color.accent)
                                    Spacer()
                                    if datingIntention == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color("Gold"))
                                            .font(.system(size: 20))
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(datingIntention == option ? Color("Gold") : Color("Gold").opacity(0.3), lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Save/Next button
                    VStack(spacing: 16) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(1.2)
                        } else {
                            Button(action: {
                                if isProfileSetup {
                                    saveAndContinue()
                                } else {
                                    saveChanges()
                                }
                            }) {
                                Text(isProfileSetup ? "Next" : "Save Changes")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(datingIntention != "" ? Color("Gold") : Color.gray.opacity(0.3))
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: datingIntention != "")
                            }
                            .disabled(datingIntention == "")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
                .padding()
                .navigationBarBackButtonHidden(false)
                .navigationBarItems(leading: 
                    Button(action: {
                        if isProfileSetup {
                            // In profile setup, we want to go back to the previous incomplete field
                            dismiss()
                        } else {
                            selectedTab = "Profile"
                            dismiss()
                        }
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
                    datingIntention = intention
                }
            }
        }
    }
    
    private func saveChanges() {
        guard !datingIntention.isEmpty else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        db.collection("users").document(userId).updateData([
            "datingIntention": datingIntention
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
    
    private func saveAndContinue() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Prevent multiple taps while saving
        guard !isLoading else { return }
        isLoading = true
        
        let data: [String: Any] = [
            "datingIntention": datingIntention
        ]
        
        db.collection("users").document(userId).updateData(data) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("Error saving dating intention: \(error.localizedDescription)")
                }
                return
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
                if self.isProfileSetup {
                    self.profileViewModel.shouldAdvanceToNextStep = true
                } else {
                    self.dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditDatingIntentionView(isAuthenticated: .constant(true), selectedTab: .constant("Profile"))
    }
} 