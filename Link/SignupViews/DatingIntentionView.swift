import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct DatingIntentionView: View {
    @Binding var isAuthenticated: Bool
    @Binding var currentStep: Int
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedIntention: String?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var navigateToEthnicity = false
    
    private let db = Firestore.firestore()
    
    private let intentionOptions = [
        "Long-term relationship",
        "Marriage",
        "Casual dating",
        "Friendship first",
        "Still figuring it out"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("What are you looking for?")
                .font(.title)
                .padding(.top)
            
            Text("Select your dating intention")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            SignupProgressView(currentStep: 7, totalSteps: 17)
                .padding(.vertical, 20)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(intentionOptions, id: \.self) { intention in
                        Button(action: { selectedIntention = intention }) {
                            HStack {
                                Text(intention)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedIntention == intention {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedIntention == intention ? Color.blue.opacity(0.1) : Color(.systemGray6))
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
                Button(action: saveIntentionAndContinue) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedIntention != nil ? Color.blue : Color.gray)
                        )
                }
                .disabled(selectedIntention == nil)
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
        .navigationDestination(isPresented: $navigateToEthnicity) {
            EthnicitySelectionView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        }
    }
    
    private func saveIntentionAndContinue() {
        guard let intention = selectedIntention else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        let userData: [String: Any] = [
            "datingIntention": intention,
            "setupProgress": SignupProgress.datingIntentionComplete.rawValue
        ]
        
        db.collection("users").document(userId).updateData(userData) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving intention: \(error.localizedDescription)"
                showError = true
                return
            }
            
            withAnimation {
                appViewModel.updateProgress(.datingIntentionComplete)
                currentStep = 8
            }
        }
    }
}

#Preview {
    NavigationView {
        DatingIntentionView(isAuthenticated: .constant(true), currentStep: .constant(0))
            .environmentObject(AppViewModel())
    }
} 
