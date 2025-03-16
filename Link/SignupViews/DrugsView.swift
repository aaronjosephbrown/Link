import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct DrugsView: View {
    @Binding var isAuthenticated: Bool
    @Binding var currentStep: Int
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedOption: String?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var setupComplete = false
    
    private let db = Firestore.firestore()
    
    private let drugOptions = [
        "Never",
        "Sometimes",
        "Often",
        "Prefer not to say"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Drug Use")
                .font(.title)
                .padding(.top)
            
            Text("Do you use recreational drugs?")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("What's your stance on recreational drugs?")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            SignupProgressView(currentStep: 16, totalSteps: 17)
                .padding(.vertical, 20)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(drugOptions, id: \.self) { option in
                        Button(action: { selectedOption = option }) {
                            HStack {
                                Text(option)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedOption == option ? Color.blue.opacity(0.1) : Color(.systemGray6))
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
                    Text("Complete Setup")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedOption != nil ? Color.blue : Color.gray)
                        )
                }
                .disabled(selectedOption == nil)
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
        .navigationDestination(isPresented: $setupComplete) {
            MainView(isAuthenticated: $isAuthenticated)
        }
    }
    
    private func saveAndContinue() {
        guard let option = selectedOption else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        let userData: [String: Any] = [
            "drugUse": option,
            "setupProgress": SignupProgress.complete.rawValue
        ]
        
        db.collection("users").document(userId).updateData(userData) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving drug use information: \(error.localizedDescription)"
                showError = true
                return
            }
            
            withAnimation {
                appViewModel.updateProgress(.complete)
                currentStep = 17
            }
        }
    }
}

#Preview {
    NavigationView {
        DrugsView(isAuthenticated: .constant(true), currentStep: .constant(0))
            .environmentObject(AppViewModel())
    }
} 