import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ChildrenFormView: View {
    @Binding var isAuthenticated: Bool
    @Binding var currentStep: Int
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var hasChildren = false
    @State private var numberOfChildren = 1
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Do you have children?")
                .font(.title)
                .padding(.top)
            
            SignupProgressView(currentStep: 8, totalSteps: 17)
                .padding(.vertical, 20)
            
            Toggle("I have children", isOn: $hasChildren)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
            if hasChildren {
                Stepper("Number of children: \(numberOfChildren)", value: $numberOfChildren, in: 1...10)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
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
                                .fill(Color.blue)
                        )
                }
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
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        let userData: [String: Any] = [
            "hasChildren": hasChildren,
            "numberOfChildren": hasChildren ? numberOfChildren : 0,
            "setupProgress": SignupProgress.childrenComplete.rawValue
        ]
        
        db.collection("users").document(userId).updateData(userData) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving children information: \(error.localizedDescription)"
                showError = true
                return
            }
            
            withAnimation {
                appViewModel.updateProgress(.childrenComplete)
                currentStep = 9
            }
        }
    }
}

#Preview {
    NavigationView {
        ChildrenFormView(isAuthenticated: .constant(true), currentStep: .constant(0))
            .environmentObject(AppViewModel())
    }
} 