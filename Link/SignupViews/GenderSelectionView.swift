import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct GenderSelectionView: View {
    @Binding var isAuthenticated: Bool
    @Binding var currentStep: Int
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedGender: String?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let db = Firestore.firestore()
    
    private let genderOptions = [
        "Male",
        "Female",
        "Non-binary",
        "Transgender",
        "Gender Fluid",
        "Prefer not to say",
        "Other"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("What's your gender?")
                .font(.title)
                .padding(.top)
            
            Text("Select your gender")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            SignupProgressView(currentStep: currentStep, totalSteps: 17)
                .padding(.vertical, 20)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(genderOptions, id: \.self) { gender in
                        Button(action: { selectedGender = gender }) {
                            HStack {
                                Text(gender)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedGender == gender {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedGender == gender ? Color.blue.opacity(0.1) : Color(.systemGray6))
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
                Button(action: saveGenderAndContinue) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedGender != nil ? Color.blue : Color.gray)
                        )
                }
                .disabled(selectedGender == nil)
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
    }
    
    private func saveGenderAndContinue() {
        guard let gender = selectedGender else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        let userData: [String: Any] = [
            "gender": gender,
            "setupProgress": SignupProgress.genderComplete.rawValue
        ]
        
        db.collection("users").document(userId).updateData(userData) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving gender: \(error.localizedDescription)"
                showError = true
                return
            }
            
            appViewModel.updateProgress(.genderComplete)
            currentStep = 4
        }
    }
}

#Preview {
    NavigationView {
        GenderSelectionView(isAuthenticated: .constant(true), currentStep: .constant(0))
    }
} 
