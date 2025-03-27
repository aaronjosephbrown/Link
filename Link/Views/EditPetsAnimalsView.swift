import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct PetsAnimalsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @State private var hasPets = false
    @State private var petTypes: Set<String> = []
    @State private var dateWithPets = false
    @State private var animalPreference = ""
    @State private var isLoading = true
    
    private let petTypesList = ["Dogs", "Cats", "Birds", "Fish", "Reptiles", "Other"]
    private let animalPreferences = ["Love animals", "Like animals", "Neutral", "Prefer no pets"]
    private let db = Firestore.firestore()
    
    var body: some View {
        BackgroundView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text("Pets & Animals")
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
                            // Pet Ownership
                            Toggle("Do you have pets?", isOn: $hasPets)
                                .foregroundColor(Color.accent)
                                .tint(Color("Gold"))
                            
                            if hasPets {
                                // Pet Types
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("What types of pets do you have?")
                                        .foregroundColor(Color.accent)
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(petTypesList, id: \.self) { type in
                                                Button(action: {
                                                    if petTypes.contains(type) {
                                                        petTypes.remove(type)
                                                    } else {
                                                        petTypes.insert(type)
                                                    }
                                                }) {
                                                    Text(type)
                                                        .padding(.horizontal, 16)
                                                        .padding(.vertical, 8)
                                                        .background(petTypes.contains(type) ? Color("Gold") : Color("Gold").opacity(0.1))
                                                        .foregroundColor(petTypes.contains(type) ? .white : Color.accent)
                                                        .cornerRadius(20)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Date with Pets
                            Toggle("Would you date someone with pets?", isOn: $dateWithPets)
                                .foregroundColor(Color.accent)
                                .tint(Color("Gold"))
                            
                            // Animal Preference
                            VStack(alignment: .leading, spacing: 8) {
                                Text("How do you feel about animals?")
                                    .foregroundColor(Color.accent)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(animalPreferences, id: \.self) { preference in
                                            Button(action: { animalPreference = preference }) {
                                                Text(preference)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(animalPreference == preference ? Color("Gold") : Color("Gold").opacity(0.1))
                                                    .foregroundColor(animalPreference == preference ? .white : Color.accent)
                                                    .cornerRadius(20)
                                            }
                                        }
                                    }
                                }
                            }
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
                print("Error loading pets data: \(error.localizedDescription)")
                isLoading = false
                return
            }
            
            if let document = document {
                let data = document.data() ?? [:]
                
                hasPets = data["hasPets"] as? Bool ?? false
                petTypes = Set(data["petTypes"] as? [String] ?? [])
                dateWithPets = data["dateWithPets"] as? Bool ?? false
                animalPreference = data["animalPreference"] as? String ?? ""
            }
            isLoading = false
        }
    }
    
    private func saveChanges() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        let data: [String: Any] = [
            "hasPets": hasPets,
            "petTypes": Array(petTypes),
            "dateWithPets": dateWithPets,
            "animalPreference": animalPreference
        ]
        
        db.collection("users").document(userId).updateData(data) { error in
            isLoading = false
            
            if let error = error {
                print("Error saving pets data: \(error.localizedDescription)")
            } else {
                profileViewModel.updateProfileCompletion()
                dismiss()
            }
        }
    }
}

#Preview {
    PetsAnimalsView()
} 