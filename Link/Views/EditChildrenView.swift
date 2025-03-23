import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditChildrenView: View {
    @Binding var isAuthenticated: Bool
    @Binding var selectedTab: String
    @State private var hasChildren = false
    @State private var numberOfChildren = 1
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
                        Image(systemName: "person.2.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color("Gold"))
                            .padding(.bottom, 8)
                        Text("Do you have children?")
                            .font(.custom("Lora-Regular", size: 19))
                            .foregroundColor(Color.accent)
                    }
                    .padding(.top, 40)
                    
                    // Children form
                    VStack(spacing: 20) {
                        // Has children toggle
                        Button(action: { hasChildren.toggle() }) {
                            HStack {
                                Text("I have children")
                                    .font(.custom("Lora-Regular", size: 17))
                                    .foregroundColor(Color.accent)
                                Spacer()
                                if hasChildren {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color("Gold"))
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(hasChildren ? Color("Gold") : Color("Gold").opacity(0.3), lineWidth: 2)
                            )
                        }
                        
                        if hasChildren {
                            // Number of children stepper
                            HStack {
                                Text("Number of children:")
                                    .font(.custom("Lora-Regular", size: 17))
                                    .foregroundColor(Color.accent)
                                Spacer()
                                HStack(spacing: 20) {
                                    Button(action: { if numberOfChildren > 1 { numberOfChildren -= 1 } }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(Color("Gold"))
                                    }
                                    .disabled(numberOfChildren <= 1)
                                    
                                    Text("\(numberOfChildren)")
                                        .font(.custom("Lora-Regular", size: 17))
                                        .foregroundColor(Color.accent)
                                        .frame(minWidth: 30)
                                    
                                    Button(action: { if numberOfChildren < 10 { numberOfChildren += 1 } }) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(Color("Gold"))
                                    }
                                    .disabled(numberOfChildren >= 10)
                                }
                            }
                            .padding()
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
                                            .fill(Color("Gold"))
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: true)
                            }
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
                    loadUserChildren()
                }
            }
        }
    }
    
    private func loadUserChildren() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error loading children information: \(error.localizedDescription)")
                return
            }
            
            if let document = document {
                DispatchQueue.main.async {
                    hasChildren = document.data()?["hasChildren"] as? Bool ?? false
                    numberOfChildren = document.data()?["numberOfChildren"] as? Int ?? 1
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
        
        let userData: [String: Any] = [
            "hasChildren": hasChildren,
            "numberOfChildren": hasChildren ? numberOfChildren : 0
        ]
        
        db.collection("users").document(userId).updateData(userData) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving children information: \(error.localizedDescription)"
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
        EditChildrenView(isAuthenticated: .constant(true), selectedTab: .constant("Profile"))
    }
} 