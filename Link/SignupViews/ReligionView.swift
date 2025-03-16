import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ReligionView: View {
    @Binding var isAuthenticated: Bool
    @Binding var currentStep: Int
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedReligion: String?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var navigateToPolitics = false
    
    private let db = Firestore.firestore()
    
    private let religions = [
        "Christianity",
        "Islam",
        "Judaism",
        "Buddhism",
        "Hinduism",
        "Sikhism",
        "Atheism",
        "Agnosticism",
        "Spiritual but not religious",
        "Other",
        "Prefer not to say"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Religion")
                .font(.title)
                .padding(.top)
            
            Text("Select your religion")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            SignupProgressView(currentStep: 11, totalSteps: 17)
                .padding(.vertical, 20)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(religions, id: \.self) { religion in
                        Button(action: { selectedReligion = religion }) {
                            HStack {
                                Text(religion)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedReligion == religion {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedReligion == religion ? Color.blue.opacity(0.1) : Color(.systemGray6))
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            if isLoading {
                ProgressView()
            } else {
                Button(action: saveAndContinue) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedReligion != nil ? Color.blue : Color.gray)
                        )
                }
                .disabled(selectedReligion == nil)
                .padding(.horizontal)
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .navigationDestination(isPresented: $navigateToPolitics) {
            PoliticalView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        }
    }
    
    private func saveAndContinue() {
        guard let religion = selectedReligion else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        let userData: [String: Any] = [
            "religion": religion,
            "setupProgress": SignupProgress.religionComplete.rawValue
        ]
        
        db.collection("users").document(userId).updateData(userData) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving religion: \(error.localizedDescription)"
                showError = true
                return
            }
            
            withAnimation {
                appViewModel.updateProgress(.religionComplete)
                currentStep = 12
                navigateToPolitics = true
            }
        }
    }
}

#Preview {
    NavigationView {
        ReligionView(isAuthenticated: .constant(true), currentStep: .constant(0))
            .environmentObject(AppViewModel())
    }
} 
