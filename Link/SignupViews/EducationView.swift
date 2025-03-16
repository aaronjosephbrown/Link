import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EducationView: View {
    @Binding var isAuthenticated: Bool
    @Binding var currentStep: Int
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedEducation: String?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let db = Firestore.firestore()
    
    private let educationLevels = [
        "High School",
        "Some College",
        "Associate's Degree",
        "Bachelor's Degree",
        "Master's Degree",
        "Doctorate",
        "Trade School",
        "Other"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Education")
                .font(.title)
                .padding(.top)
            
            Text("What's your education level?")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            SignupProgressView(currentStep: 10, totalSteps: 17)
                .padding(.vertical, 20)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(educationLevels, id: \.self) { level in
                        Button(action: { selectedEducation = level }) {
                            HStack {
                                Text(level)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedEducation == level {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedEducation == level ? Color.blue.opacity(0.1) : Color(.systemGray6))
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
                                .fill(selectedEducation != nil ? Color.blue : Color.gray)
                        )
                }
                .disabled(selectedEducation == nil)
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
    
    private func saveAndContinue() {
        guard let education = selectedEducation else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        let userData: [String: Any] = [
            "education": education,
            "setupProgress": SignupProgress.educationComplete.rawValue
        ]
        
        db.collection("users").document(userId).updateData(userData) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving education: \(error.localizedDescription)"
                showError = true
                return
            }
            
            withAnimation {
                appViewModel.updateProgress(.educationComplete)
                currentStep = 11
            }
        }
    }
}

#Preview {
    NavigationView {
        EducationView(isAuthenticated: .constant(true), currentStep: .constant(0))
            .environmentObject(AppViewModel())
    }
} 
