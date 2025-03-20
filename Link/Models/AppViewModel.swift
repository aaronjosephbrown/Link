import SwiftUI
import FirebaseFirestore
import FirebaseAuth

enum SignupProgress: String {
    case initial
    case nameEntered
    case emailVerified
    case dobVerified
    case genderComplete
    case sexualityComplete
    case sexualityPreferenceComplete
    case heightComplete
    case datingIntentionComplete
    case childrenComplete
    case familyPlansComplete
    case educationComplete
    case religionComplete
    case ethnicityComplete
    case drinkingComplete
    case smokingComplete
    case politicsComplete
    case drugsComplete
    case locationComplete
    case photosComplete
    case complete
}

class AppViewModel: ObservableObject {
    @AppStorage("currentSignupProgress") private var currentSignupProgress = SignupProgress.initial.rawValue
    @AppStorage("setupComplete") private var localSetupComplete = false
    @Published var isAuthenticated = false
    
    private let db = Firestore.firestore()
    
    func resetProgress() {
        // Reset local storage
        currentSignupProgress = SignupProgress.initial.rawValue
        localSetupComplete = false
        
        // Reset Firestore if user is authenticated
        if let userId = Auth.auth().currentUser?.uid {
            let userData: [String: Any] = ["setupProgress": SignupProgress.initial.rawValue]
            db.collection("users").document(userId).updateData(userData) { error in
                if let error = error {
                    print("Error resetting progress in Firestore: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func updateProgress(_ progress: SignupProgress) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        print("Updating progress to: \(progress)")
        
        // Update local storage immediately
        currentSignupProgress = progress.rawValue
        localSetupComplete = progress == .complete
        
        // Update Firestore
        let userData: [String: Any] = ["setupProgress": progress.rawValue]
        db.collection("users").document(userId).updateData(userData) { [weak self] error in
            if let error = error {
                print("Error updating progress: \(error.localizedDescription)")
                // Revert local storage if server update fails
                self?.currentSignupProgress = SignupProgress.initial.rawValue
                self?.localSetupComplete = false
            } else {
                print("Successfully updated progress to: \(progress)")
            }
        }
    }
    
    func checkCurrentProgress(completion: @escaping (SignupProgress) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.initial)
            return
        }
        
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            if let error = error {
                print("Error checking progress: \(error.localizedDescription)")
                completion(.initial)
                return
            }
            
            if let document = document,
               let progress = document.data()?["setupProgress"] as? String {
                self?.currentSignupProgress = progress
                if let signupProgress = SignupProgress(rawValue: progress) {
                    completion(signupProgress)
                } else {
                    completion(.initial)
                }
            } else {
                completion(.initial)
            }
        }
    }
    
    func getCurrentProgress() -> SignupProgress {
        return SignupProgress(rawValue: currentSignupProgress) ?? .initial
    }
    
    func getCurrentStep() -> Int {
        switch getCurrentProgress() {
        case .initial:
            return 0
        case .nameEntered:
            return 1
        case .emailVerified:
            return 2
        case .dobVerified:
            return 3
        case .genderComplete:
            return 4
        case .sexualityComplete:
            return 5
        case .sexualityPreferenceComplete:
            return 6
        case .heightComplete:
            return 7
        case .datingIntentionComplete:
            return 8
        case .childrenComplete:
            return 9
        case .familyPlansComplete:
            return 10
        case .educationComplete:
            return 11
        case .religionComplete:
            return 12
        case .ethnicityComplete:
            return 13
        case .drinkingComplete:
            return 14
        case .smokingComplete:
            return 15
        case .politicsComplete:
            return 16
        case .drugsComplete:
            return 17
        case .locationComplete:
            return 18
        case .photosComplete:
            return 19
        case .complete:
            return 20
        @unknown default:
            return 0
        }
    }
} 