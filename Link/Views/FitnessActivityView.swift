import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FitnessActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @State private var activityLevel = ""
    @State private var favoriteActivities: Set<String> = []
    @State private var preferSimilarFitness = false
    @State private var isLoading = true
    
    private let activityLevels = ["Sedentary", "Active", "Gym Regular", "Athlete"]
    private let activities = ["Hiking", "Yoga", "Gym", "Dance", "Team Sports", "Running", "Swimming", "Cycling"]
    private let db = Firestore.firestore()
    
    var body: some View {
        BackgroundView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text("Fitness & Activity Level")
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
                            // Activity Level
                            VStack(alignment: .leading, spacing: 8) {
                                Text("How would you describe your activity level?")
                                    .foregroundColor(Color.accent)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(activityLevels, id: \.self) { level in
                                            Button(action: { activityLevel = level }) {
                                                Text(level)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(activityLevel == level ? Color("Gold") : Color("Gold").opacity(0.1))
                                                    .foregroundColor(activityLevel == level ? .white : Color.accent)
                                                    .cornerRadius(20)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Favorite Activities
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Favorite ways to stay active")
                                    .foregroundColor(Color.accent)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(activities, id: \.self) { activity in
                                            Button(action: {
                                                if favoriteActivities.contains(activity) {
                                                    favoriteActivities.remove(activity)
                                                } else {
                                                    favoriteActivities.insert(activity)
                                                }
                                            }) {
                                                Text(activity)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(favoriteActivities.contains(activity) ? Color("Gold") : Color("Gold").opacity(0.1))
                                                    .foregroundColor(favoriteActivities.contains(activity) ? .white : Color.accent)
                                                    .cornerRadius(20)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Toggle("Would you prefer a partner with a similar fitness level?", isOn: $preferSimilarFitness)
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
                print("Error loading fitness data: \(error.localizedDescription)")
                isLoading = false
                return
            }
            
            if let document = document {
                let data = document.data() ?? [:]
                
                activityLevel = data["activityLevel"] as? String ?? ""
                favoriteActivities = Set(data["favoriteActivities"] as? [String] ?? [])
                preferSimilarFitness = data["preferSimilarFitness"] as? Bool ?? false
            }
            isLoading = false
        }
    }
    
    private func saveChanges() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        let data: [String: Any] = [
            "activityLevel": activityLevel,
            "favoriteActivities": Array(favoriteActivities),
            "preferSimilarFitness": preferSimilarFitness
        ]
        
        db.collection("users").document(userId).updateData(data) { error in
            isLoading = false
            
            if let error = error {
                print("Error saving fitness data: \(error.localizedDescription)")
            } else {
                profileViewModel.updateProfileCompletion()
                dismiss()
            }
        }
    }
}

#Preview {
    FitnessActivityView()
} 