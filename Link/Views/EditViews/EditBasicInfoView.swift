import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditBasicInfoView: View {
    @Binding var isAuthenticated: Bool
    @Binding var selectedTab: String
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var dateOfBirth = Date()
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    var isProfileSetup: Bool = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        BackgroundView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 60))
                            .foregroundColor(Color("Gold"))
                            .padding(.bottom, 8)
                        Text("Basic Information")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.accent)
                    }
                    .padding(.top, 40)
                    
                    // Form
                    VStack(spacing: 20) {
                        // First Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("First Name")
                                .foregroundColor(Color.accent)
                            TextField("Enter your first name", text: $firstName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.words)
                        }
                        
                        // Last Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last Name")
                                .foregroundColor(Color.accent)
                            TextField("Enter your last name", text: $lastName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.words)
                        }
                        
                        // Date of Birth
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date of Birth")
                                .foregroundColor(Color.accent)
                            DatePicker("Select your date of birth", selection: $dateOfBirth, displayedComponents: .date)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Next Button
                    VStack(spacing: 16) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(Color("Gold"))
                        } else {
                            Button(action: saveAndContinue) {
                                Text("Next")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(!firstName.isEmpty && !lastName.isEmpty ? Color("Gold") : Color.gray.opacity(0.3))
                                    )
                            }
                            .disabled(firstName.isEmpty || lastName.isEmpty)
                        }
                    }
                    .padding()
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadExistingData()
            }
        }
    }
    
    private func loadExistingData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error loading basic info: \(error.localizedDescription)")
                return
            }
            
            if let document = document {
                let data = document.data() ?? [:]
                
                firstName = data["firstName"] as? String ?? ""
                lastName = data["lastName"] as? String ?? ""
                if let timestamp = data["dateOfBirth"] as? Timestamp {
                    dateOfBirth = Date(timeIntervalSince1970: Double(timestamp._seconds))
                }
            }
        }
    }
    
    private func saveAndContinue() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Prevent multiple taps while saving
        guard !isLoading else { return }
        isLoading = true
        
        let timestamp = Timestamp(_seconds: Int64(dateOfBirth.timeIntervalSince1970), _nanoseconds: 0)
        let data: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "dateOfBirth": timestamp
        ]
        
        db.collection("users").document(userId).updateData(data) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("Error saving basic info: \(error.localizedDescription)")
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
    EditBasicInfoView(isAuthenticated: .constant(true), selectedTab: .constant(""), isProfileSetup: true)
        .environmentObject(ProfileViewModel())
} 