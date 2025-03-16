import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct SexualityPreferenceView: View {
    @Binding var isAuthenticated: Bool
    @Binding var currentStep: Int
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedPreferences: Set<String> = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let db = Firestore.firestore()
    
    private let preferenceOptions = [
        "Men",
        "Women",
        "Non-binary people",
        "Everyone"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Dating Preferences")
                .font(.title)
                .padding(.top)
            
            Text("Select who you want to date")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            SignupProgressView(currentStep: 5, totalSteps: 17)
                .padding(.vertical, 20)
            
            Text("Who would you like to date?")
                .font(.caption)
                .foregroundColor(.gray)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(preferenceOptions, id: \.self) { preference in
                        Button(action: { togglePreference(preference) }) {
                            HStack {
                                Text(preference)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedPreferences.contains(preference) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedPreferences.contains(preference) ? Color.blue.opacity(0.1) : Color(.systemGray6))
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
                Button(action: savePreferencesAndContinue) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(!selectedPreferences.isEmpty ? Color.blue : Color.gray)
                        )
                }
                .disabled(selectedPreferences.isEmpty)
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
    
    private func togglePreference(_ preference: String) {
        if preference == "Everyone" {
            selectedPreferences = ["Everyone"]
        } else {
            selectedPreferences.remove("Everyone")
            if selectedPreferences.contains(preference) {
                selectedPreferences.remove(preference)
            } else {
                selectedPreferences.insert(preference)
            }
        }
    }
    
    private func savePreferencesAndContinue() {
        guard !selectedPreferences.isEmpty else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        let userData: [String: Any] = [
            "datingPreferences": Array(selectedPreferences),
            "setupProgress": SignupProgress.sexualityPreferenceComplete.rawValue
        ]
        
        db.collection("users").document(userId).updateData(userData) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving preferences: \(error.localizedDescription)"
                showError = true
                return
            }
            
            withAnimation {
                appViewModel.updateProgress(.sexualityPreferenceComplete)
                currentStep = 6
            }
        }
    }
}

#Preview {
    NavigationView {
        SexualityPreferenceView(isAuthenticated: .constant(true), currentStep: .constant(0))
            .environmentObject(AppViewModel())
    }
} 