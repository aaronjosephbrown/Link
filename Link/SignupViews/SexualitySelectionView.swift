import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SexualitySelectionView: View {
    @Binding var isAuthenticated: Bool
    @Binding var currentStep: Int
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedSexuality: String?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let db = Firestore.firestore()
    
    private let sexualityOptions = [
        "Straight",
        "Gay",
        "Lesbian",
        "Bisexual",
        "Pansexual",
        "Asexual",
        "Queer",
        "Prefer not to say",
        "Other"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("What's your sexuality?")
                .font(.title)
                .padding(.top)
            
            Text("Select your sexuality")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            SignupProgressView(currentStep: 4, totalSteps: 17)
                .padding(.vertical, 20)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(sexualityOptions, id: \.self) { sexuality in
                        Button(action: { selectedSexuality = sexuality }) {
                            HStack {
                                Text(sexuality)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedSexuality == sexuality {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedSexuality == sexuality ? Color.blue.opacity(0.1) : Color(.systemGray6))
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
                Button(action: saveSexualityAndContinue) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedSexuality != nil ? Color.blue : Color.gray)
                        )
                }
                .disabled(selectedSexuality == nil)
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
    
    private func saveSexualityAndContinue() {
        guard let sexuality = selectedSexuality else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        let userData: [String: Any] = [
            "sexuality": sexuality,
            "setupProgress": SignupProgress.sexualityComplete.rawValue
        ]
        
        db.collection("users").document(userId).updateData(userData) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving sexuality: \(error.localizedDescription)"
                showError = true
                return
            }
            
            withAnimation {
                appViewModel.updateProgress(.sexualityComplete)
                currentStep = 5
            }
        }
    }
}

#Preview {
    NavigationView {
        SexualitySelectionView(isAuthenticated: .constant(true), currentStep: .constant(0))
            .environmentObject(AppViewModel())
    }
} 