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
    
    private let db = Firestore.firestore()
    
    private let intentionOptions = [
        "Long-term relationship",
        "Marriage",
        "Casual dating",
        "Friendship first",
        "Still figuring it out"
    ]
    
    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color("Gold"))
                            .symbolEffect(.bounce, options: .repeating)
                        
                        Text("What are you looking for?")
                            .font(.custom("Lora-Regular", size: 24))
                            .foregroundColor(Color.accent)
                        
                        Text("This helps us find better matches for you")
                            .font(.custom("Lora-Regular", size: 16))
                            .foregroundColor(Color.accent.opacity(0.7))
                    }
                    .padding(.top, 40)
                    
                    // Progress indicator
                    SignupProgressView(currentStep: currentStep)
                    
                    // Intention options
                    VStack(spacing: 12) {
                        ForEach(intentionOptions, id: \.self) { option in
                            Button(action: { selectedIntention = option }) {
                                HStack {
                                    Text(option)
                                        .font(.custom("Lora-Regular", size: 17))
                                        .foregroundColor(Color.accent)
                                    Spacer()
                                    if selectedIntention == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color("Gold"))
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedIntention == option ? Color("Gold") : Color("Gold").opacity(0.3), lineWidth: 2)
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
                                            .fill(selectedIntention != nil ? Color("Gold") : Color.gray.opacity(0.3))
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: selectedIntention != nil)
                            }
                            .disabled(selectedIntention == nil)
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
    NavigationStack {
        DatingIntentionView(
            isAuthenticated: .constant(false),
            currentStep: .constant(7)
        )
        .environmentObject(AppViewModel())
    }
    .preferredColorScheme(.light)
}

// Dark mode preview
#Preview("Dark Mode") {
    NavigationStack {
        DatingIntentionView(
            isAuthenticated: .constant(false),
            currentStep: .constant(7)
        )
        .environmentObject(AppViewModel())
    }
    .preferredColorScheme(.dark)
} 
