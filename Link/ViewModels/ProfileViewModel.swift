import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftUI

class ProfileViewModel: ObservableObject {
    @Published var profileCompletion: Double = 0.0
    @Published var completedFields: Int = 0
    @Published var totalFields: Int = 0
    @Published var incompleteFields: [IncompleteField] = []
    @Published var profileSetupCompleted: Bool = false
    
    // AppStorage for persistent storage
    @AppStorage("profileCompletion") private var storedProfileCompletion: Double = 0.0
    @AppStorage("profileSetupCompleted") private var storedProfileSetupCompleted: Bool = false
    @AppStorage("lastProfileUpdate") private var lastProfileUpdate: Double = 0
    @AppStorage("lastProfileChange") private var lastProfileChange: Double = 0
    @AppStorage("incompleteFields") private var storedIncompleteFields: Data = Data()
    
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    // Define all profile fields in one place
    private let profileFields: [(field: String, type: FieldType, required: Int)] = [
        // Basic Profile Fields
        ("firstName", .string, 1),
        ("bio", .string, 1),
        ("location", .geoPoint, 1),
        ("occupation", .string, 1),
        
        // Profile Pictures
        ("profilePictures", .array, 6),
        
        // Profile Setup Fields
        ("heightPreference", .string, 1),
        ("bodyType", .string, 1),
        ("preferredPartnerHeight", .string, 1),
        ("activityLevel", .string, 1),
        ("favoriteActivities", .array, 1),
        ("diet", .string, 1),
        ("hasPets", .boolean, 1),
        ("petTypes", .array, 1),
        ("animalPreference", .string, 1),
        
        // Additional Profile Fields
        ("gender", .string, 1),
        ("sexuality", .string, 1),
        ("datingIntention", .string, 1),
        ("hasChildren", .boolean, 1),
        ("familyPlans", .string, 1),
        ("height", .string, 1),
        ("sexualityPreference", .string, 1),
        ("education", .string, 1),
        ("religion", .string, 1),
        ("ethnicity", .string, 1),
        ("drinkingHabit", .string, 1),
        ("smokingHabits", .string, 1),
        ("politicalViews", .string, 1),
        ("drugUse", .string, 1)
    ]
    
    private enum FieldType {
        case string
        case array
        case geoPoint
        case boolean
    }
    
    init() {
        // Load stored values on initialization
        self.profileCompletion = storedProfileCompletion
        self.profileSetupCompleted = storedProfileSetupCompleted
        
        // Decode stored incomplete fields
        if let decodedFields = try? JSONDecoder().decode([IncompleteField].self, from: storedIncompleteFields) {
            self.incompleteFields = decodedFields
        }
        
        // Set up Firestore listener for profile changes
        setupProfileListener()
    }
    
    deinit {
        // Clean up listener when ViewModel is deallocated
        listenerRegistration?.remove()
    }
    
    private func setupProfileListener() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        listenerRegistration = db.collection("users").document(userId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening to profile changes: \(error.localizedDescription)")
                    return
                }
                
                if documentSnapshot != nil {
                    // Update lastProfileChange timestamp when document changes
                    self.lastProfileChange = Date().timeIntervalSince1970
                }
            }
    }
    
    func updateProfileCompletion(completion: Double, incompleteFields: [IncompleteField]) {
        // Update published properties
        self.profileCompletion = completion
        self.incompleteFields = incompleteFields
        self.profileSetupCompleted = completion >= 1.0
        
        // Store values in AppStorage
        self.storedProfileCompletion = completion
        self.storedProfileSetupCompleted = completion >= 1.0
        self.lastProfileUpdate = Date().timeIntervalSince1970
        
        // Store incomplete fields
        if let encodedFields = try? JSONEncoder().encode(incompleteFields) {
            self.storedIncompleteFields = encodedFields
        }
        
        // Calculate completed and total fields from incomplete fields
        let totalFields = incompleteFields.reduce(0) { $0 + ($1.required ?? 0) }
        let completedFields = totalFields - incompleteFields.reduce(0) { $0 + ($1.current ?? 0) }
        
        self.completedFields = completedFields
        self.totalFields = totalFields
    }
    
    func shouldRefreshProfile() -> Bool {
        // Only refresh if:
        // 1. More than 5 minutes have passed since last update AND
        // 2. The profile has changed since the last update
        let fiveMinutes: TimeInterval = 5 * 60
        let hasTimeElapsed = Date().timeIntervalSince1970 - lastProfileUpdate > fiveMinutes
        let hasProfileChanged = lastProfileChange > lastProfileUpdate
        
        return hasTimeElapsed && hasProfileChanged
    }
    
    func updateProfileCompletion() {
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
                
                for (field, type, required) in self.profileFields {
                    total += required
                    
                    switch type {
                    case .string:
                        if let value = data[field] as? String, !value.isEmpty {
                            completed += required
                        }
                    case .array:
                        if let array = data[field] as? [Any], !array.isEmpty {
                            if field == "profilePictures" {
                                completed += min(array.count, required)
                            } else {
                                completed += required
                            }
                        }
                    case .geoPoint:
                        if data[field] != nil {
                            completed += required
                        }
                    case .boolean:
                        if let value = data[field] as? Bool {
                            completed += required
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    let completion = Double(completed) / Double(total)
                    let incompleteFields = self.calculateIncompleteFields(from: data)
                    self.updateProfileCompletion(completion: completion, incompleteFields: incompleteFields)
                }
            }
        }
    }
    
    private func calculateIncompleteFields(from data: [String: Any]) -> [IncompleteField] {
        var incompleteFields: [IncompleteField] = []
        
        for (field, type, required) in profileFields {
            let displayName = field.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression).capitalized
            let message = "Please complete your \(field.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression).lowercased())"
            
            switch type {
            case .string:
                if let value = data[field] as? String, value.isEmpty {
                    incompleteFields.append(IncompleteField(
                        field: field,
                        displayName: displayName,
                        message: message,
                        required: required,
                        current: 0
                    ))
                }
            case .array:
                if let array = data[field] as? [Any] {
                    if field == "profilePictures" {
                        let current = array.count
                        if current < required {
                            incompleteFields.append(IncompleteField(
                                field: field,
                                displayName: displayName,
                                message: "Please add more profile pictures",
                                required: required,
                                current: current
                            ))
                        }
                    } else if array.isEmpty {
                        incompleteFields.append(IncompleteField(
                            field: field,
                            displayName: displayName,
                            message: message,
                            required: required,
                            current: 0
                        ))
                    }
                }
            case .geoPoint:
                if data[field] == nil {
                    incompleteFields.append(IncompleteField(
                        field: field,
                        displayName: displayName,
                        message: "Please enable location services",
                        required: required,
                        current: 0
                    ))
                }
            case .boolean:
                if data[field] == nil {
                    incompleteFields.append(IncompleteField(
                        field: field,
                        displayName: displayName,
                        message: message,
                        required: required,
                        current: 0
                    ))
                }
            }
        }
        
        return incompleteFields
    }
} 
