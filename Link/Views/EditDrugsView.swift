import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditDrugsView: View {
    @Binding var isAuthenticated: Bool
    @Binding var selectedTab: String
    @State private var selectedDrugs: String?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    private let db = Firestore.firestore()
    
    private let drugsOptions = [
        "Never",
        "Socially",
        "Regularly",
        "Prefer not to say"
    ]
    
    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "pills")
                            .font(.system(size: 60))
                            .foregroundColor(Color("Gold"))
                            .padding(.bottom, 8)
                        Text("Drugs")
                            .font(.custom("Lora-Regular", size: 19))
                            .foregroundColor(Color.accent)
                    }
                    .padding(.top, 40)
                    
                    // Drugs options
                    VStack(spacing: 12) {
                        ForEach(drugsOptions, id: \.self) { option in
                            Button(action: { selectedDrugs = option }) {
                                HStack {
                                    Text(option)
                                        .font(.custom("Lora-Regular", size: 17))
                                        .foregroundColor(Color.accent)
                                    Spacer()
                                    if selectedDrugs == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color("Gold"))
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedDrugs == option ? Color("Gold") : Color("Gold").opacity(0.3), lineWidth: 2)
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
                                            .fill(selectedDrugs != nil ? Color("Gold") : Color.gray.opacity(0.3))
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: selectedDrugs != nil)
                            }
                            .disabled(selectedDrugs == nil)
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
                    loadUserDrugs()
                }
            }
        }
    }
    
    private func loadUserDrugs() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error loading drugs preference: \(error.localizedDescription)")
                return
            }
            
            if let document = document,
               let drugs = document.data()?["drugs"] as? String {
                DispatchQueue.main.async {
                    selectedDrugs = drugs
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let drugs = selectedDrugs else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        db.collection("users").document(userId).updateData([
            "drugs": drugs
        ]) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving drugs preference: \(error.localizedDescription)"
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
        EditDrugsView(isAuthenticated: .constant(true), selectedTab: .constant("Profile"))
    }
} 