import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FamilyPlansView: View {
    @Binding var isAuthenticated: Bool
    @Binding var currentStep: Int
    @EnvironmentObject var appViewModel: AppViewModel
    let hasChildren: Bool
    @State private var selectedPlan: String?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var navigateToEducation = false
    
    private let db = Firestore.firestore()
    
    private let familyPlanOptions = [
        "I want children",
        "I don't want children",
        "I might want children",
        "I have all the children I want"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Family Plans")
                .font(.title)
                .padding(.top)
            
            Text(hasChildren ? "Do you want more children?" : "Do you want children in the future?")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("What are your future family plans?")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            SignupProgressView(currentStep: 9, totalSteps: 17)
                .padding(.vertical, 20)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(familyPlanOptions, id: \.self) { plan in
                        Button(action: { selectedPlan = plan }) {
                            HStack {
                                Text(plan)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedPlan == plan {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedPlan == plan ? Color.blue.opacity(0.1) : Color(.systemGray6))
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
                                .fill(selectedPlan != nil ? Color.blue : Color.gray)
                        )
                }
                .disabled(selectedPlan == nil)
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
        .navigationDestination(isPresented: $navigateToEducation) {
            EducationView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        }
    }
    
    private func saveAndContinue() {
        guard let plan = selectedPlan else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        let userData: [String: Any] = [
            "familyPlans": plan,
            "setupProgress": SignupProgress.familyPlansComplete.rawValue
        ]
        
        db.collection("users").document(userId).updateData(userData) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving family plans: \(error.localizedDescription)"
                showError = true
                return
            }
            
            withAnimation {
                appViewModel.updateProgress(.familyPlansComplete)
                currentStep = 10
                navigateToEducation = true
            }
        }
    }
}

#Preview {
    NavigationView {
        FamilyPlansView(isAuthenticated: .constant(true), currentStep: .constant(0), hasChildren: false)
            .environmentObject(AppViewModel())
    }
} 
