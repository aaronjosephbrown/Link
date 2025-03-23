import Foundation
import FirebaseFirestore
import FirebaseAuth

class ProfileViewModel: ObservableObject {
    @Published var profileCompletion: Double = 0.0
    @Published var completedFields: Int = 0
    @Published var totalFields: Int = 0
    
    private let db = Firestore.firestore()
    
    func calculateProfileCompletion() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error calculating profile completion: \(error.localizedDescription)")
                return
            }
            
            if let document = document {
                let data = document.data() ?? [:]
                var completed = 0
                var total = 0
                
                // Basic Profile Fields
                let basicFields = ["name", "bio", "location", "occupation"]
                for field in basicFields {
                    if let value = data[field] as? String, !value.isEmpty {
                        completed += 1
                    }
                    total += 1
                }
                
                // Profile Pictures (6 required)
                if let photos = data["profilePictures"] as? [String] {
                    completed += min(photos.count, 6)
                    total += 6
                }
                
                // Profile Setup Fields
                let setupFields = [
                    "heightPreference", "bodyType", "preferredPartnerHeight",
                    "activityLevel", "favoriteActivities", "diet",
                    "hasPets", "petTypes", "animalPreference"
                ]
                
                for field in setupFields {
                    if let value = data[field] {
                        if let array = value as? [Any] {
                            if !array.isEmpty {
                                completed += 1
                            }
                        } else if let string = value as? String, !string.isEmpty {
                            completed += 1
                        }
                    }
                    total += 1
                }
                
                // Additional Profile Fields
                let additionalFields = [
                    "gender", "sexuality", "datingIntention", "children",
                    "familyPlans", "height", "sexualityPreference", "education",
                    "religion", "ethnicity", "drinking", "smoking", "politics", "drugs"
                ]
                
                for field in additionalFields {
                    if let value = data[field] as? String, !value.isEmpty {
                        completed += 1
                    }
                    total += 1
                }
                
                DispatchQueue.main.async {
                    self.completedFields = completed
                    self.totalFields = total
                    self.profileCompletion = Double(completed) / Double(total)
                }
            }
        }
    }
    
    // Call this method after any profile data is saved
    func updateProfileCompletion() {
        calculateProfileCompletion()
    }
} 