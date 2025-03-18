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
    @State private var navigateToEthnicity = false
    
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
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "hands.and.sparkles.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color("Gold"))
                            .symbolEffect(.bounce, options: .repeating)
                        
                        Text("Your Religious Views")
                            .font(.custom("Lora-Regular", size: 24))
                            .foregroundColor(Color.accent)
                        
                        Text("This helps us find better matches for you")
                            .font(.custom("Lora-Regular", size: 16))
                            .foregroundColor(Color.accent.opacity(0.7))
                    }
                    .padding(.top, 40)
                    
                    // Progress indicator
                    SignupProgressView(currentStep: currentStep, totalSteps: 17)
                    
                    // Religion options
                    VStack(spacing: 16) {
                        ForEach(religions, id: \.self) { religion in
                            Button(action: { selectedReligion = religion }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(religion)
                                            .font(.custom("Lora-Regular", size: 17))
                                            .foregroundColor(selectedReligion == religion ? .white : Color.accent)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedReligion == religion {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedReligion == religion ? Color("Gold") : Color("Gold").opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedReligion == religion ? Color("Gold") : Color("Gold").opacity(0.3), lineWidth: 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
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
                                HStack {
                                    Text("Continue")
                                        .font(.system(size: 17, weight: .semibold))
                                    
                                    if selectedReligion != nil {
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedReligion != nil ? Color("Gold") : Color.gray.opacity(0.3))
                                )
                                .animation(.easeInOut(duration: 0.2), value: selectedReligion)
                            }
                            .disabled(selectedReligion == nil)
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
        .navigationDestination(isPresented: $navigateToEthnicity) {
            EthnicitySelectionView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
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
                navigateToEthnicity = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        ReligionView(
            isAuthenticated: .constant(false),
            currentStep: .constant(11)
        )
        .environmentObject(AppViewModel())
    }
    .preferredColorScheme(.light)
}

// Dark mode preview
#Preview("Dark Mode") {
    NavigationStack {
        ReligionView(
            isAuthenticated: .constant(false),
            currentStep: .constant(11)
        )
        .environmentObject(AppViewModel())
    }
    .preferredColorScheme(.dark)
} 
