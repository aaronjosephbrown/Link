import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SmokingHabitsView: View {
    @Binding var isAuthenticated: Bool
    @Binding var currentStep: Int
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedSmokingHabit: String?
    @State private var usesTobacco = false
    @State private var usesWeed = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var navigateToDrugs = false
    
    private let db = Firestore.firestore()
    
    private let smokingOptions = [
        "Never",
        "Rarely",
        "Sometimes",
        "Often",
        "Everyday",
        "Prefer not to say"
    ]
    
    private var showsAdditionalQuestions: Bool {
        if let habit = selectedSmokingHabit {
            return habit != "Never" && habit != "Prefer not to say"
        }
        return false
    }
    
    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "smoke.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color("Gold"))
                            .symbolEffect(.bounce, options: .repeating)
                        
                        Text("Your Smoking Habits")
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
                        ForEach(smokingOptions, id: \.self) { habit in
                            Button(action: { selectedSmokingHabit = habit }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(habit)
                                            .font(.custom("Lora-Regular", size: 17))
                                            .foregroundColor(selectedSmokingHabit == habit ? .white : Color.accent)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedSmokingHabit == habit {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedSmokingHabit == habit ? Color("Gold") : Color("Gold").opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedSmokingHabit == habit ? Color("Gold") : Color("Gold").opacity(0.3), lineWidth: 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        if showsAdditionalQuestions {
                            VStack(spacing: 16) {
                                Toggle(isOn: $usesTobacco) {
                                    Text("Do you use tobacco products?")
                                        .font(.custom("Lora-Regular", size: 16))
                                        .foregroundColor(Color.accent)
                                }
                                .tint(Color("Gold"))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color("Gold").opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                                )
                                
                                Toggle(isOn: $usesWeed) {
                                    Text("Do you use marijuana?")
                                        .font(.custom("Lora-Regular", size: 16))
                                        .foregroundColor(Color.accent)
                                }
                                .tint(Color("Gold"))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color("Gold").opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                                )
                            }
                            .padding(.top)
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
                                    
                                    if selectedSmokingHabit != nil {
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedSmokingHabit != nil ? Color("Gold") : Color.gray.opacity(0.3))
                                )
                                .animation(.easeInOut(duration: 0.2), value: selectedSmokingHabit)
                            }
                            .disabled(selectedSmokingHabit == nil)
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
        .navigationDestination(isPresented: $navigateToDrugs) {
            DrugsView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        }
    }
    
    private func saveAndContinue() {
        guard let smokingHabit = selectedSmokingHabit else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        var userData: [String: Any] = [
            "smokingHabits": smokingHabit,
            "setupProgress": SignupProgress.smokingComplete.rawValue
        ]
        
        if showsAdditionalQuestions {
            userData["usesTobacco"] = usesTobacco
            userData["usesMarijuana"] = usesWeed
        }
        
        db.collection("users").document(userId).updateData(userData) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving smoking habits: \(error.localizedDescription)"
                showError = true
                return
            }
            
            withAnimation {
                appViewModel.updateProgress(.smokingComplete)
                currentStep = 15
                navigateToDrugs = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        SmokingHabitsView(
            isAuthenticated: .constant(false),
            currentStep: .constant(14)
        )
        .environmentObject(AppViewModel())
    }
    .preferredColorScheme(.light)
}

// Dark mode preview
#Preview("Dark Mode") {
    NavigationStack {
        SmokingHabitsView(
            isAuthenticated: .constant(false),
            currentStep: .constant(14)
        )
        .environmentObject(AppViewModel())
    }
    .preferredColorScheme(.dark)
} 
