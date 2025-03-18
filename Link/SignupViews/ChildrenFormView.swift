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
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "figure.2.and.child")
                            .font(.system(size: 60))
                            .foregroundColor(Color("Gold"))
                            .padding(.bottom, 8)
                        
                        Text("Do you have children?")
                            .font(.custom("Lora-Regular", size: 19))
                            .foregroundColor(Color.accent)
                    }
                    .padding(.top, 40)
                    
                    // Progress indicator
                    SignupProgressView(currentStep: currentStep, totalSteps: 17)
                    
                    // Children form
                    VStack(spacing: 20) {
                        // Has children toggle
                        Button(action: { hasChildren.toggle() }) {
                            HStack {
                                Text("I have children")
                                    .font(.custom("Lora-Regular", size: 17))
                                    .foregroundColor(Color.accent)
                                Spacer()
                                if hasChildren {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color("Gold"))
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(hasChildren ? Color("Gold") : Color("Gold").opacity(0.3), lineWidth: 2)
                            )
                        }
                        
                        if hasChildren {
                            // Number of children stepper
                            HStack {
                                Text("Number of children:")
                                    .font(.custom("Lora-Regular", size: 17))
                                    .foregroundColor(Color.accent)
                                Spacer()
                                HStack(spacing: 20) {
                                    Button(action: { if numberOfChildren > 1 { numberOfChildren -= 1 } }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(Color("Gold"))
                                    }
                                    .disabled(numberOfChildren <= 1)
                                    
                                    Text("\(numberOfChildren)")
                                        .font(.custom("Lora-Regular", size: 17))
                                        .foregroundColor(Color.accent)
                                        .frame(minWidth: 30)
                                    
                                    Button(action: { if numberOfChildren < 10 { numberOfChildren += 1 } }) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(Color("Gold"))
                                    }
                                    .disabled(numberOfChildren >= 10)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                            )
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
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color("Gold"))
                                )
                                .animation(.easeInOut(duration: 0.2), value: true)
                            }
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
    NavigationStack {
        ChildrenFormView(
            isAuthenticated: .constant(false),
            currentStep: .constant(8)
        )
        .environmentObject(AppViewModel())
    }
    .preferredColorScheme(.light)
}

// Dark mode preview
#Preview("Dark Mode") {
    NavigationStack {
        ChildrenFormView(
            isAuthenticated: .constant(false),
            currentStep: .constant(8)
        )
        .environmentObject(AppViewModel())
    }
    .preferredColorScheme(.dark)
} 