import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct DietaryPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @State private var diet = ""
    @State private var dietaryImportance: Double = 5
    @State private var dateDifferentDiet = false
    @State private var dietaryNumberScale: CGFloat = 1.0
    @State private var dietaryNumberOpacity: Double = 1.0
    @State private var isLoading = true
    
    private let diets = ["Omnivore", "Vegetarian", "Vegan", "Pescatarian", "Keto", "Paleo"]
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
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(Color("Gold"))
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
                                        ForEach(diets, id: \.self) { dietType in
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
                                        .onChange(of: dietaryImportance) { _ in
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
                    
                    // Save Button
                    Button(action: saveChanges) {
                        Text("Save Changes")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("Gold"))
                            .cornerRadius(12)
                    }
                    .padding()
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
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        let data: [String: Any] = [
            "diet": diet,
            "dietaryImportance": dietaryImportance,
            "dateDifferentDiet": dateDifferentDiet
        ]
        
        db.collection("users").document(userId).updateData(data) { error in
            isLoading = false
            
            if let error = error {
                print("Error saving dietary data: \(error.localizedDescription)")
            } else {
                profileViewModel.updateProfileCompletion()
                dismiss()
            }
        }
    }
}

#Preview {
    DietaryPreferencesView()
} 