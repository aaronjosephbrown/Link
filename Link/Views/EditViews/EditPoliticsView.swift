import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditPoliticsView: View {
    @Binding var isAuthenticated: Bool
    @Binding var selectedTab: String
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var politicalViews = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    var isProfileSetup: Bool = false
    
    private let politicalOptions = [
        "Very Liberal",
        "Liberal",
        "Moderate",
        "Conservative",
        "Very Conservative",
        "Not Political",
        "Prefer not to say"
    ]
    private let db = Firestore.firestore()
    
    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
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
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color("Gold"))
                            .padding(.bottom, 8)
                        Text("Edit Political Views")
                            .font(.custom("Lora-Regular", size: 19))
                            .foregroundColor(Color.accent)
                    }
                    .padding(.top, 40)
                    
                    // Politics options
                    VStack(spacing: 16) {
                        ForEach(politicalOptions, id: \.self) { option in
                            Button(action: { politicalViews = option }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(option)
                                            .font(.custom("Lora-Regular", size: 17))
                                            .foregroundColor(politicalViews == option ? .white : Color.accent)
                                    }
                                    
                                    Spacer()
                                    
                                    if politicalViews == option {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(politicalViews == option ? Color("Gold") : Color("Gold").opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(politicalViews == option ? Color("Gold") : Color("Gold").opacity(0.3), lineWidth: 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
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
                                HStack {
                                    Text(isProfileSetup ? "Next" : "Save Changes")
                                        .font(.system(size: 17, weight: .semibold))
                                    
                                    if politicalViews != "" {
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(politicalViews != "" ? Color("Gold") : Color.gray.opacity(0.3))
                                )
                                .animation(.easeInOut(duration: 0.2), value: politicalViews != "")
                            }
                            .disabled(politicalViews == "")
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
                    loadUserPolitics()
                }
            }
        }
    }
    
    private func loadUserPolitics() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error loading politics preference: \(error.localizedDescription)")
                return
            }
            
            if let document = document {
                let data = document.data() ?? [:]
                DispatchQueue.main.async {
                    self.politicalViews = data["politicalViews"] as? String ?? ""
                }
            }
        }
    }
    
    private func saveChanges() {
        guard !politicalViews.isEmpty else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        let data: [String: Any] = [
            "politicalViews": politicalViews
        ]
        
        db.collection("users").document(userId).updateData(data) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Error saving politics preference: \(error.localizedDescription)"
                    self.showError = true
                }
                return
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.selectedTab = "Profile"
                self.dismiss()
            }
        }
    }
    
    private func saveAndContinue() {
        guard !politicalViews.isEmpty else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        // Prevent multiple taps while saving
        guard !isLoading else { return }
        isLoading = true
        
        let data: [String: Any] = [
            "politicalViews": politicalViews
        ]
        
        db.collection("users").document(userId).updateData(data) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Error saving political views: \(error.localizedDescription)"
                    self.showError = true
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
        EditPoliticsView(isAuthenticated: .constant(true), selectedTab: .constant("Profile"))
    }
} 