import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftUI

class ProfileViewModel: ObservableObject {
    @Published var profileCompletion: Double = 0.0
    @Published var shouldAdvanceToNextStep: Bool = false
    @Published var completedFields: Int = 0
    @Published var totalFields: Int = 0
    @Published var incompleteFields: [IncompleteField] = []
    @Published var profileSetupCompleted: Bool = false
    private var lastUpdateTime: Date?
    
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
        ("lastName", .string, 1),
        ("bio", .string, 1),
        ("location", .geoPoint, 1),
        ("occupation", .string, 1),
        ("email", .string, 1),
        ("dateOfBirth", .string, 1),
        
        // Profile Pictures
        ("profilePictures", .array, 6),
        
        // Profile Setup Fields
        ("heightPreference", .string, 1),
        ("bodyType", .string, 1),
        ("preferredPartnerHeight", .string, 1),
        ("heightImportance", .number, 1),
        ("activityLevel", .string, 1),
        ("favoriteActivities", .array, 1),
        ("preferSimilarFitness", .boolean, 1),
        ("diet", .string, 1),
        ("dietaryImportance", .number, 1),
        ("dateDifferentDiet", .boolean, 1),
        
        // Additional Profile Fields
        ("gender", .string, 1),
        ("sexuality", .string, 1),
        ("sexualityPreference", .string, 1),
        ("datingIntention", .string, 1),
        ("hasChildren", .boolean, 1),
        ("numberOfChildren", .number, 1),
        ("familyPlans", .string, 1),
        ("height", .string, 1),
        ("education", .string, 1),
        ("religion", .string, 1),
        ("ethnicity", .string, 1),
        ("ethnicitySubcategory", .string, 1),
        ("drinkingHabit", .string, 1),
        ("smokingHabits", .string, 1),
        ("politicalViews", .string, 1),
        ("drugUse", .string, 1),
        ("usesMarijuana", .boolean, 1),
        ("usesTobacco", .boolean, 1)
    ]
    
    private enum FieldType {
        case string
        case array
        case geoPoint
        case boolean
        case number
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
                        if let array = data[field] as? [Any] {
                            if field == "profilePictures" {
                                completed += min(array.count, required)
                            } else if !array.isEmpty {
                                completed += required
                            }
                        }
                    case .geoPoint:
                        if data[field] != nil {
                            completed += required
                        }
                    case .boolean:
                            if data[field] is Bool {
                            completed += required
                        }
                    case .number:
                            if data[field] is NSNumber {
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
        
        print("\n=== Profile Completion Debug ===")
        print("Checking fields for completion...")
        
        for (field, type, required) in profileFields {
            let displayName = field.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression).capitalized
            let message = "Please complete your \(field.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression).lowercased())"
            
            // Check if the field exists in the data
            if data[field] == nil {
                print("❌ Field missing: \(field)")
                incompleteFields.append(IncompleteField(
                    field: field,
                    displayName: displayName,
                    message: message,
                    required: required,
                    current: 0
                ))
                continue
            }
            
            switch type {
            case .string:
                if let value = data[field] as? String {
                    if value.isEmpty {
                        print("❌ Empty string: \(field)")
                    } else {
                        print("✅ String field complete: \(field) = \(value)")
                    }
                    if value.isEmpty {
                        incompleteFields.append(IncompleteField(
                            field: field,
                            displayName: displayName,
                            message: message,
                            required: required,
                            current: 0
                        ))
                    }
                }
            case .array:
                if let array = data[field] as? [Any] {
                    if field == "profilePictures" {
                        let current = array.count
                        print("📸 Profile pictures: \(current)/\(required)")
                        if current < required {
                            incompleteFields.append(IncompleteField(
                                field: field,
                                displayName: displayName,
                                message: "Please add more profile pictures",
                                required: required,
                                current: current
                            ))
                        }
                    } else {
                        print("📦 Array field: \(field) = \(array.count) items")
                        if array.isEmpty {
                            print("❌ Empty array: \(field)")
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
            case .geoPoint:
                print("📍 GeoPoint field: \(field)")
                if data[field] == nil {
                    print("❌ Missing location: \(field)")
                    incompleteFields.append(IncompleteField(
                        field: field,
                        displayName: displayName,
                        message: "Please enable location services",
                        required: required,
                        current: 0
                    ))
                }
            case .boolean:
                if let value = data[field] as? Bool {
                    print("🔘 Boolean field: \(field) = \(value)")
                } else {
                    print("❌ Missing boolean: \(field)")
                    incompleteFields.append(IncompleteField(
                        field: field,
                        displayName: displayName,
                        message: message,
                        required: required,
                        current: 0
                    ))
                }
            case .number:
                if let value = data[field] as? NSNumber {
                    print("🔢 Number field: \(field) = \(value)")
                } else {
                    print("❌ Missing number: \(field)")
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
        
        print("\n=== Incomplete Fields Summary ===")
        if incompleteFields.isEmpty {
            print("🎉 All fields are complete!")
        } else {
            print("Found \(incompleteFields.count) incomplete fields:")
            for field in incompleteFields {
                print("- \(field.field): \(field.message)")
            }
        }
        print("==============================\n")
        
        return incompleteFields
    }
} 
