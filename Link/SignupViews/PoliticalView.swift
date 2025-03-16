import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PoliticalView: View {
    @Binding var isAuthenticated: Bool
    @Binding var currentStep: Int
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedPolitics: String?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var navigateToDrinking = false
    
    private let db = Firestore.firestore()
    
    private let politicalOptions = [
        "Very Liberal",
        "Liberal",
        "Moderate",
        "Conservative",
        "Very Conservative",
        "Apolitical",
        "Other",
        "Prefer not to say"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("What are your political views?")
                .font(.title)
                .padding(.top)
            
            Text("Select your political stance")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            SignupProgressView(currentStep: 15, totalSteps: 17)
                .padding(.vertical, 20)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(politicalOptions, id: \.self) { politics in
                        Button(action: { selectedPolitics = politics }) {
                            HStack {
                                Text(politics)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedPolitics == politics {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedPolitics == politics ? Color.blue.opacity(0.1) : Color(.systemGray6))
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
                                .fill(selectedPolitics != nil ? Color.blue : Color.gray)
                        )
                }
                .disabled(selectedPolitics == nil)
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
        .navigationDestination(isPresented: $navigateToDrinking) {
            DrinkingHabitsView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        }
    }
    
    private func saveAndContinue() {
        guard let politics = selectedPolitics else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        let userData: [String: Any] = [
            "politicalViews": politics,
            "setupProgress": SignupProgress.politicsComplete.rawValue
        ]
        
        db.collection("users").document(userId).updateData(userData) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving political views: \(error.localizedDescription)"
                showError = true
                return
            }
            
            withAnimation {
                appViewModel.updateProgress(.politicsComplete)
                currentStep = 16
                navigateToDrinking = true
            }
        }
    }
}

#Preview {
    NavigationView {
        PoliticalView(isAuthenticated: .constant(true), currentStep: .constant(0))
            .environmentObject(AppViewModel())
    }
} 
