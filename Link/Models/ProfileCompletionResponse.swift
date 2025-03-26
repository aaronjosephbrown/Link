import Foundation

struct IncompleteField: Codable {
    let field: String
    let displayName: String
    let message: String
    let required: Int?
    let current: Int?
}

struct ProfileCompletionResponse: Codable {
    let success: Bool
    let user: UserData
    let profileCompletion: Double
    let incompleteFields: [IncompleteField]
    
    struct UserData: Codable {
        let id: String
        let firstName: String?
        let lastName: String?
        let email: String?
        let dateOfBirth: Timestamp?
        let sexualityPreference: String?
        let height: String?
        let hasChildren: Bool?
        let education: String?
        let religion: String?
        let drinkingHabit: String?
        let smokingHabits: String?
        let politicalViews: String?
        let drugUse: String?
        let setupProgress: String?
        let sexuality: String?
        let drinking: String?
        let drugs: String?
        let smoking: String?
        let gender: String?
        let children: String?
        let politics: String?
        let numberOfChildren: Int?
        let datingIntention: String?
        let familyPlans: String?
        let ethnicity: String?
        let ethnicitySubcategory: String?
        let favoriteActivities: [String]?
        let heightPreference: String?
        let dietaryImportance: Int?
        let heightImportance: Int?
        let bodyType: String?
        let profileSetupCompleted: Bool?
        let preferredPartnerHeight: String?
        let activityLevel: String?
        let preferSimilarFitness: Bool?
        let dateDifferentDiet: Bool?
        let diet: String?
        let animalPreference: String?
        let dateWithPets: Bool?
        let petTypes: [String]?
        let occupation: String?
        let hasPets: String?
        let name: String?
        let bio: String?
        let location: Location?
        let profilePictures: [String]?
        let interests: [String]?
    }
    
    struct Location: Codable {
        let _latitude: Double
        let _longitude: Double
    }
}

// Helper struct for Firestore Timestamp
struct Timestamp: Codable {
    let _seconds: Int64
    let _nanoseconds: Int32
} 