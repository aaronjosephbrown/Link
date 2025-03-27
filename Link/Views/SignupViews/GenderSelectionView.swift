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
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.2.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color("Gold"))
                            .padding(.bottom, 8)
                            .symbolEffect(.bounce, options: .repeating)
                        Text("What's your gender?")
                            .font(.custom("Lora-Regular", size: 19))
                            .foregroundColor(Color.accent)
                    }
                    .padding(.top, 40)
                    
                    // Progress indicator
                    SignupProgressView(currentStep: currentStep)
                    
                    // Gender options
                    VStack(spacing: 12) {
                        ForEach(genderOptions, id: \.self) { option in
                            Button(action: { selectedGender = option }) {
                                HStack {
                                    Text(option)
                                        .font(.custom("Lora-Regular", size: 17))
                                        .foregroundColor(Color.accent)
                                    Spacer()
                                    if selectedGender == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color("Gold"))
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedGender == option ? Color("Gold") : Color("Gold").opacity(0.3), lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Continue button
                    VStack(spacing: 16) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(1.2)
                        } else {
                            Button(action: saveAndContinue) {
                                Text("Continue")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(selectedGender != nil ? Color("Gold") : Color.gray.opacity(0.3))
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: selectedGender != nil)
                            }
                            .disabled(selectedGender == nil)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
                .padding()
                .navigationBarBackButtonHidden(true)
                .alert("Error", isPresented: $showError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(errorMessage)
                }
            }
        }
    }
    
    private func saveAndContinue() {
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
            
            withAnimation {
                appViewModel.updateProgress(.genderComplete)
                currentStep = 4
            }
        }
    }
}

#Preview {
    NavigationStack {
        GenderSelectionView(
            isAuthenticated: .constant(false),
            currentStep: .constant(3)
        )
        .environmentObject(AppViewModel())
    }
    .preferredColorScheme(.light)
}

// Dark mode preview
#Preview("Dark Mode") {
    NavigationStack {
        GenderSelectionView(
            isAuthenticated: .constant(false),
            currentStep: .constant(3)
        )
        .environmentObject(AppViewModel())
    }
    .preferredColorScheme(.dark)
} 
