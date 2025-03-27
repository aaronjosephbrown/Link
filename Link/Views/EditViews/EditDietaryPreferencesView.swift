import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditDietaryPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @State private var diet = ""
    @State private var dietaryImportance: Double = 5
    @State private var dateDifferentDiet = false
    @State private var dietaryNumberScale: CGFloat = 1.0
    @State private var dietaryNumberOpacity: Double = 1.0
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    var isProfileSetup: Bool = false
    
    private let dietaryOptions = ["Omnivore", "Vegetarian", "Vegan", "Pescatarian", "Kosher", "Halal", "Other"]
    private let db = Firestore.firestore()
    
    var body: some View {
        BackgroundView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text("Dietary Preferences")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.accent)
                        Spacer()
                        if !isProfileSetup {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundColor(Color("Gold"))
                            }
                        }
                    }
                    .padding()
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(Color("Gold"))
                    } else {
                        VStack(spacing: 24) {
                            // Diet Type
                            VStack(alignment: .leading, spacing: 8) {
                                Text("What's your diet?")
                                    .foregroundColor(Color.accent)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(dietaryOptions, id: \.self) { dietType in
                                            Button(action: { diet = dietType }) {
                                                Text(dietType)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(diet == dietType ? Color("Gold") : Color("Gold").opacity(0.1))
                                                    .foregroundColor(diet == dietType ? .white : Color.accent)
                                                    .cornerRadius(20)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Dietary Importance
                            VStack(alignment: .leading, spacing: 8) {
                                Text("How important is dietary compatibility?")
                                    .foregroundColor(Color.accent)
                                Slider(value: $dietaryImportance, in: 1...10, step: 1)
                                    .tint(Color("Gold"))
                                HStack {
                                    Text("Not at all")
                                    Spacer()
                                    Text("\(Int(dietaryImportance))")
                                        .fontWeight(.bold)
                                        .foregroundColor(Color("Gold"))
                                        .scaleEffect(dietaryNumberScale)
                                        .opacity(dietaryNumberOpacity)
                                        .onChange(of: dietaryImportance) { _ , _ in
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                dietaryNumberScale = 1.3
                                                dietaryNumberOpacity = 0.7
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                    dietaryNumberScale = 1.0
                                                    dietaryNumberOpacity = 1.0
                                                }
                                            }
                                        }
                                    Spacer()
                                    Text("Very")
                                }
                                .font(.caption)
                                .foregroundColor(Color.accent.opacity(0.7))
                            }
                            
                            Toggle("Would you date someone with different dietary preferences?", isOn: $dateDifferentDiet)
                                .foregroundColor(Color.accent)
                                .tint(Color("Gold"))
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    // Save/Next Button
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
                                    if isProfileSetup {
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color("Gold"))
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
                .navigationBarBackButtonHidden(false)
                .navigationBarItems(leading: 
                    Button(action: {
                        if isProfileSetup {
                            dismiss()
                        } else {
                            profileViewModel.updateProfileCompletion()
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
            }
            .onAppear {
                loadExistingData()
            }
        }
    }
    
    private func loadExistingData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error loading dietary data: \(error.localizedDescription)")
                isLoading = false
                return
            }
            
            if let document = document {
                let data = document.data() ?? [:]
                
                diet = data["diet"] as? String ?? ""
                dietaryImportance = data["dietaryImportance"] as? Double ?? 5
                dateDifferentDiet = data["dateDifferentDiet"] as? Bool ?? false
            }
            isLoading = false
        }
    }
    
    private func saveChanges() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        let data: [String: Any] = [
            "diet": diet,
            "dietaryImportance": dietaryImportance,
            "dateDifferentDiet": dateDifferentDiet
        ]
        
        db.collection("users").document(userId).updateData(data) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving dietary data: \(error.localizedDescription)"
                showError = true
                return
            }
            
            profileViewModel.updateProfileCompletion()
            dismiss()
        }
    }
    
    private func saveAndContinue() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Prevent multiple taps while saving
        guard !isLoading else { return }
        isLoading = true
        
        let data: [String: Any] = [
            "diet": diet,
            "dietaryImportance": dietaryImportance,
            "dateDifferentDiet": dateDifferentDiet
        ]
        
        db.collection("users").document(userId).updateData(data) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("Error saving dietary data: \(error.localizedDescription)")
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
    EditDietaryPreferencesView()
}
