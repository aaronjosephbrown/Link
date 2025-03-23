import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditEducationView: View {
    @Binding var isAuthenticated: Bool
    @Binding var selectedTab: String
    @State private var selectedEducation: String?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    private let db = Firestore.firestore()
    
    private let educationOptions = [
        "High School",
        "Some College",
        "Associate's Degree",
        "Bachelor's Degree",
        "Master's Degree",
        "Doctorate",
        "Prefer not to say"
    ]
    
    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "book.circle")
                            .font(.system(size: 60))
                            .foregroundColor(Color("Gold"))
                            .padding(.bottom, 8)
                        Text("Education")
                            .font(.custom("Lora-Regular", size: 19))
                            .foregroundColor(Color.accent)
                    }
                    .padding(.top, 40)
                    
                    // Education options
                    VStack(spacing: 12) {
                        ForEach(educationOptions, id: \.self) { option in
                            Button(action: { selectedEducation = option }) {
                                HStack {
                                    Text(option)
                                        .font(.custom("Lora-Regular", size: 17))
                                        .foregroundColor(Color.accent)
                                    Spacer()
                                    if selectedEducation == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color("Gold"))
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedEducation == option ? Color("Gold") : Color("Gold").opacity(0.3), lineWidth: 2)
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
                                            .fill(selectedEducation != nil ? Color("Gold") : Color.gray.opacity(0.3))
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: selectedEducation != nil)
                            }
                            .disabled(selectedEducation == nil)
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
                    loadUserEducation()
                }
            }
        }
    }
    
    private func loadUserEducation() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error loading education: \(error.localizedDescription)")
                return
            }
            
            if let document = document,
               let education = document.data()?["education"] as? String {
                DispatchQueue.main.async {
                    selectedEducation = education
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let education = selectedEducation else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        db.collection("users").document(userId).updateData([
            "education": education
        ]) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving education: \(error.localizedDescription)"
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
        EditEducationView(isAuthenticated: .constant(true), selectedTab: .constant("Profile"))
    }
} 