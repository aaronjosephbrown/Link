import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct DrinkingHabitsView: View {
    @Binding var isAuthenticated: Bool
    @Binding var currentStep: Int
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedHabit: DrinkingHabit?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var navigateToSmoking = false
    
    private let db = Firestore.firestore()
    
    private enum DrinkingHabit: String, CaseIterable {
        case never = "Never"
        case socially = "Socially"
        case regularly = "Regularly"
        case frequently = "Frequently"
        case preferNotToSay = "Prefer not to say"
        
        var description: String {
            switch self {
            case .never: return "I don't drink"
            case .socially: return "I drink occasionally at social events"
            case .regularly: return "I drink a few times a week"
            case .frequently: return "I drink most days"
            case .preferNotToSay: return "I prefer not to share this information"
            }
        }
    }
    
    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "wineglass.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color("Gold"))
                            .symbolEffect(.bounce, options: .repeating)
                        
                        Text("Your Drinking Habits")
                            .font(.custom("Lora-Regular", size: 24))
                            .foregroundColor(Color.accent)
                        
                        Text("This helps us find better matches for you")
                            .font(.custom("Lora-Regular", size: 16))
                            .foregroundColor(Color.accent.opacity(0.7))
                    }
                    .padding(.top, 40)
                    
                    // Progress indicator
                    SignupProgressView(currentStep: currentStep, totalSteps: 17)
                    
                    // Options
                    VStack(spacing: 16) {
                        ForEach(DrinkingHabit.allCases, id: \.self) { habit in
                            Button(action: { selectedHabit = habit }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(habit.rawValue)
                                            .font(.custom("Lora-Regular", size: 17))
                                            .foregroundColor(selectedHabit == habit ? .white : Color.accent)
                                        
                                        Text(habit.description)
                                            .font(.custom("Lora-Regular", size: 14))
                                            .foregroundColor(selectedHabit == habit ? .white.opacity(0.8) : Color.accent.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedHabit == habit {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedHabit == habit ? Color("Gold") : Color("Gold").opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedHabit == habit ? Color("Gold") : Color("Gold").opacity(0.3), lineWidth: 2)
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
                            Button(action: saveDrinkingHabit) {
                                HStack {
                                    Text("Continue")
                                        .font(.system(size: 17, weight: .semibold))
                                    
                                    if selectedHabit != nil {
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedHabit != nil ? Color("Gold") : Color.gray.opacity(0.3))
                                )
                                .animation(.easeInOut(duration: 0.2), value: selectedHabit)
                            }
                            .disabled(selectedHabit == nil)
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
        .navigationDestination(isPresented: $navigateToSmoking) {
            SmokingHabitsView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        }
    }
    
    private func saveDrinkingHabit() {
        guard let habit = selectedHabit else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        let userData: [String: Any] = [
            "drinkingHabit": habit.rawValue,
            "setupProgress": SignupProgress.drinkingComplete.rawValue
        ]
        
        db.collection("users").document(userId).updateData(userData) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving drinking habit: \(error.localizedDescription)"
                showError = true
                return
            }
            
            withAnimation {
                appViewModel.updateProgress(.drinkingComplete)
                currentStep = 15
                navigateToSmoking = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        DrinkingHabitsView(
            isAuthenticated: .constant(false),
            currentStep: .constant(13)
        )
        .environmentObject(AppViewModel())
    }
    .preferredColorScheme(.light)
}

// Dark mode preview
#Preview("Dark Mode") {
    NavigationStack {
        DrinkingHabitsView(
            isAuthenticated: .constant(false),
            currentStep: .constant(13)
        )
        .environmentObject(AppViewModel())
    }
    .preferredColorScheme(.dark)
} 
