import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AppearanceLifestyleView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @State private var bodyType = ""
    @State private var heightPreference = ""
    @State private var heightImportance: Double = 5
    @State private var preferredPartnerHeight = ""
    @State private var heightNumberScale: CGFloat = 1.0
    @State private var heightNumberOpacity: Double = 1.0
    @State private var isLoading = true
    
    private let bodyTypes = ["Athletic", "Slim", "Average", "Curvy", "Muscular", "Plus Size"]
    private let heightPreferences = ["Shorter", "Same height", "Taller", "No preference"]
    private let db = Firestore.firestore()
    
    var body: some View {
        BackgroundView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text("Appearance & Lifestyle")
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
                            // Body Type
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Body Type")
                                    .foregroundColor(Color.accent)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(bodyTypes, id: \.self) { type in
                                            Button(action: { bodyType = type }) {
                                                Text(type)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(bodyType == type ? Color("Gold") : Color("Gold").opacity(0.1))
                                                    .foregroundColor(bodyType == type ? .white : Color.accent)
                                                    .cornerRadius(20)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Height Preference
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your height preference")
                                    .foregroundColor(Color.accent)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(["Short", "Average", "Tall"], id: \.self) { preference in
                                            Button(action: { heightPreference = preference }) {
                                                Text(preference)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(heightPreference == preference ? Color("Gold") : Color("Gold").opacity(0.1))
                                                    .foregroundColor(heightPreference == preference ? .white : Color.accent)
                                                    .cornerRadius(20)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Height Importance
                            VStack(alignment: .leading, spacing: 8) {
                                Text("How important is height in a match?")
                                    .foregroundColor(Color.accent)
                                Slider(value: $heightImportance, in: 1...10, step: 1)
                                    .tint(Color("Gold"))
                                HStack {
                                    Text("Not at all")
                                    Spacer()
                                    Text("\(Int(heightImportance))")
                                        .fontWeight(.bold)
                                        .foregroundColor(Color("Gold"))
                                        .scaleEffect(heightNumberScale)
                                        .opacity(heightNumberOpacity)
                                        .onChange(of: heightImportance) { _ , _ in
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                heightNumberScale = 1.3
                                                heightNumberOpacity = 0.7
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                    heightNumberScale = 1.0
                                                    heightNumberOpacity = 1.0
                                                }
                                            }
                                        }
                                    Spacer()
                                    Text("Very important")
                                }
                                .font(.caption)
                                .foregroundColor(Color.accent.opacity(0.7))
                            }
                            
                            // Preferred Partner Height
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Preferred partner's height")
                                    .foregroundColor(Color.accent)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(heightPreferences, id: \.self) { preference in
                                            Button(action: { preferredPartnerHeight = preference }) {
                                                Text(preference)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(preferredPartnerHeight == preference ? Color("Gold") : Color("Gold").opacity(0.1))
                                                    .foregroundColor(preferredPartnerHeight == preference ? .white : Color.accent)
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
                print("Error loading appearance data: \(error.localizedDescription)")
                isLoading = false
                return
            }
            
            if let document = document {
                let data = document.data() ?? [:]
                
                bodyType = data["bodyType"] as? String ?? ""
                heightPreference = data["heightPreference"] as? String ?? ""
                heightImportance = data["heightImportance"] as? Double ?? 5
                preferredPartnerHeight = data["preferredPartnerHeight"] as? String ?? ""
            }
            isLoading = false
        }
    }
    
    private func saveChanges() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        let data: [String: Any] = [
            "bodyType": bodyType,
            "heightPreference": heightPreference,
            "heightImportance": heightImportance,
            "preferredPartnerHeight": preferredPartnerHeight
        ]
        
        db.collection("users").document(userId).updateData(data) { error in
            isLoading = false
            
            if let error = error {
                print("Error saving appearance data: \(error.localizedDescription)")
            } else {
                profileViewModel.updateProfileCompletion()
                dismiss()
            }
        }
    }
}

#Preview {
    AppearanceLifestyleView()
} 
