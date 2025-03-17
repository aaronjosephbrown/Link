import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct DrinkingHabitsView: View {
    @Binding var isAuthenticated: Bool
    @Binding var currentStep: Int
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedDrinkingHabit: String?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var navigateToSmoking = false
    
    private let db = Firestore.firestore()
    
    private let drinkingOptions = [
        "Never",
        "Rarely",
        "Sometimes",
        "Often",
        "Everyday",
        "Prefer not to say"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Drinking Habits")
                .font(.title)
                .padding(.top)
            
            Text("What are your drinking habits?")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            SignupProgressView(currentStep: 13, totalSteps: 17)
                .padding(.vertical, 20)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(drinkingOptions, id: \.self) { habit in
                        Button(action: { selectedDrinkingHabit = habit }) {
                            HStack {
                                Text(habit)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedDrinkingHabit == habit {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedDrinkingHabit == habit ? Color.blue.opacity(0.1) : Color(.systemGray6))
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
                                .fill(selectedDrinkingHabit != nil ? Color.blue : Color.gray)
                        )
                }
                .disabled(selectedDrinkingHabit == nil)
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
        .navigationDestination(isPresented: $navigateToSmoking) {
            SmokingHabitsView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        }
    }
    
    private func saveAndContinue() {
        guard let habit = selectedDrinkingHabit else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        let userData: [String: Any] = [
            "drinkingHabits": habit,
            "setupProgress": SignupProgress.drinkingComplete.rawValue
        ]
        
        db.collection("users").document(userId).updateData(userData) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving drinking habits: \(error.localizedDescription)"
                showError = true
                return
            }
            
            withAnimation {
                appViewModel.updateProgress(.drinkingComplete)
                currentStep = 14
                navigateToSmoking = true
            }
        }
    }
}

#Preview {
    NavigationView {
        DrinkingHabitsView(isAuthenticated: .constant(true), currentStep: .constant(0))
            .environmentObject(AppViewModel())
    }
} 
