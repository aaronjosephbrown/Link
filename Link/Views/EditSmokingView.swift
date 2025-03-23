import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditSmokingView: View {
    @Binding var isAuthenticated: Bool
    @Binding var selectedTab: String
    @State private var selectedSmokingHabit: String?
    @State private var usesTobacco = false
    @State private var usesWeed = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
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
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "smoke.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color("Gold"))
                            .padding(.bottom, 8)
                        Text("Edit Smoking Habits")
                            .font(.custom("Lora-Regular", size: 19))
                            .foregroundColor(Color.accent)
                    }
                    .padding(.top, 40)
                    
                    // Smoking options
                    VStack(spacing: 12) {
                        ForEach(smokingOptions, id: \.self) { option in
                            Button(action: { selectedSmokingHabit = option }) {
                                HStack {
                                    Text(option)
                                        .font(.custom("Lora-Regular", size: 17))
                                        .foregroundColor(Color.accent)
                                    Spacer()
                                    if selectedSmokingHabit == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color("Gold"))
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedSmokingHabit == option ? Color("Gold") : Color("Gold").opacity(0.3), lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
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
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Save button
                    VStack(spacing: 16) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(1.2)
                        } else {
                            Button(action: saveChanges) {
                                Text("Save Changes")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(selectedSmokingHabit != nil ? Color("Gold") : Color.gray.opacity(0.3))
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: selectedSmokingHabit != nil)
                            }
                            .disabled(selectedSmokingHabit == nil)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
                .padding()
                .navigationBarBackButtonHidden(false)
                .navigationBarItems(leading: 
                    Button(action: {
                        selectedTab = "Profile"
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .foregroundColor(Color("Gold"))
                            Text("Back")
                                .foregroundColor(Color("Gold"))
                        }
                    }
                )
                .alert("Error", isPresented: $showError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(errorMessage)
                }
                .onAppear {
                    loadUserSmoking()
                }
            }
        }
    }
    
    private func loadUserSmoking() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error loading smoking habits: \(error.localizedDescription)")
                return
            }
            
            if let document = document {
                DispatchQueue.main.async {
                    selectedSmokingHabit = document.data()?["smokingHabits"] as? String
                    usesTobacco = document.data()?["usesTobacco"] as? Bool ?? false
                    usesWeed = document.data()?["usesMarijuana"] as? Bool ?? false
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let smokingHabit = selectedSmokingHabit else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        var userData: [String: Any] = [
            "smokingHabits": smokingHabit
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
            
            selectedTab = "Profile"
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        EditSmokingView(isAuthenticated: .constant(true), selectedTab: .constant("Profile"))
    }
} 