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
        VStack(spacing: 20) {
            Text("What are your smoking habits?")
                .font(.title)
                .padding(.top)
            
            Text("Select your smoking frequency")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            SignupProgressView(currentStep: 14, totalSteps: 17)
                .padding(.vertical, 20)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(smokingOptions, id: \.self) { habit in
                        Button(action: { selectedSmokingHabit = habit }) {
                            HStack {
                                Text(habit)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedSmokingHabit == habit {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedSmokingHabit == habit ? Color.blue.opacity(0.1) : Color(.systemGray6))
                            )
                        }
                    }
                    
                    if showsAdditionalQuestions {
                        VStack(spacing: 16) {
                            Toggle("Do you use tobacco products?", isOn: $usesTobacco)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            
                            Toggle("Do you use marijuana?", isOn: $usesWeed)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        .padding(.top)
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
                                .fill(selectedSmokingHabit != nil ? Color.blue : Color.gray)
                        )
                }
                .disabled(selectedSmokingHabit == nil)
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
    NavigationView {
        SmokingHabitsView(isAuthenticated: .constant(true), currentStep: .constant(0))
            .environmentObject(AppViewModel())
    }
} 
