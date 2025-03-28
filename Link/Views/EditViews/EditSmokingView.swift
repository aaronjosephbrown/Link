import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditSmokingView: View {
    @Binding var isAuthenticated: Bool
    @Binding var selectedTab: String
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var smokingHabit = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var usesTobacco = false
    @State private var usesWeed = false
    var isProfileSetup: Bool = false
    
    private let smokingOptions = [
        "Never",
        "Rarely",
        "Sometimes",
        "Often",
        "Everyday",
        "Prefer not to say"
    ]
    private let db = Firestore.firestore()
    
    private var showsAdditionalQuestions: Bool {
        smokingHabit != "Never" && smokingHabit != "Prefer not to say"
    }
    
    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        if !isProfileSetup {
                            HStack {
                                Spacer()
                                Button(action: { dismiss() }) {
                                    Image(systemName: "xmark")
                                        .font(.title2)
                                        .foregroundColor(Color("Gold"))
                                }
                            }
                        }
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
                    VStack(spacing: 16) {
                        ForEach(smokingOptions, id: \.self) { option in
                            Button(action: { smokingHabit = option }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(option)
                                            .font(.custom("Lora-Regular", size: 17))
                                            .foregroundColor(smokingHabit == option ? .white : Color.accent)
                                    }
                                    
                                    Spacer()
                                    
                                    if smokingHabit == option {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(smokingHabit == option ? Color("Gold") : Color("Gold").opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(smokingHabit == option ? Color("Gold") : Color("Gold").opacity(0.3), lineWidth: 2)
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
                    
                    // Save/Next button
                    VStack(spacing: 16) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(1.2)
                        } else {
                            Button(action: {
                                if isProfileSetup {
                                    saveAndContinue()
                                } else {
                                    saveChanges()
                                }
                            }) {
                                HStack {
                                    Text(isProfileSetup ? "Next" : "Save Changes")
                                        .font(.system(size: 17, weight: .semibold))
                                    
                                    if smokingHabit != "" {
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(smokingHabit != "" ? Color("Gold") : Color.gray.opacity(0.3))
                                )
                                .animation(.easeInOut(duration: 0.2), value: smokingHabit != "")
                            }
                            .disabled(smokingHabit == "")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
                .padding()
                .navigationBarBackButtonHidden(false)
                .navigationBarItems(leading: 
                    Button(action: {
                        if isProfileSetup {
                            dismiss()
                        } else {
                            selectedTab = "Profile"
                            dismiss()
                        }
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
                let data = document.data() ?? [:]
                DispatchQueue.main.async {
                    self.smokingHabit = data["smokingHabits"] as? String ?? ""
                    self.usesTobacco = data["usesTobacco"] as? Bool ?? false
                    self.usesWeed = data["usesMarijuana"] as? Bool ?? false
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        var data: [String: Any] = [
            "smokingHabits": smokingHabit
        ]
        
        if showsAdditionalQuestions {
            data["usesTobacco"] = usesTobacco
            data["usesMarijuana"] = usesWeed
        }
        
        db.collection("users").document(userId).updateData(data) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Error saving smoking habits: \(error.localizedDescription)"
                    self.showError = true
                }
                return
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.selectedTab = "Profile"
                self.dismiss()
            }
        }
    }
    
    private func saveAndContinue() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        // Prevent multiple taps while saving
        guard !isLoading else { return }
        isLoading = true
        
        var data: [String: Any] = [
            "smokingHabits": smokingHabit
        ]
        
        if showsAdditionalQuestions {
            data["usesTobacco"] = usesTobacco
            data["usesMarijuana"] = usesWeed
        }
        
        db.collection("users").document(userId).updateData(data) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Error saving smoking habits: \(error.localizedDescription)"
                    self.showError = true
                }
                return
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
                if self.isProfileSetup {
                    self.profileViewModel.shouldAdvanceToNextStep = true
                } else {
                    self.dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditSmokingView(isAuthenticated: .constant(true), selectedTab: .constant("Profile"))
    }
} 