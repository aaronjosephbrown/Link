import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileSetupFlowView: View {
    @Binding var isAuthenticated: Bool
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var currentStep = 0
    
    var body: some View {
        NavigationStack {
            content
                .navigationBarBackButtonHidden(true)
        }
        .onAppear {
            initializeStep()
        }
        .onChange(of: appViewModel.getCurrentProgress()) { _ , newProgress in
            currentStep = stepForProgress(newProgress)
        }
    }
    
    private func initializeStep() {
        let progress = appViewModel.getCurrentProgress()
        withAnimation {
            currentStep = stepForProgress(progress)
        }
    }
    
    private func stepForProgress(_ progress: SignupProgress) -> Int {
        switch progress {
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
        case .photosComplete:
            return 18
        case .complete:
            return 19
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch currentStep {
        case 0:
            UserProfileSetupView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        case 1:
            EmailCollectionView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        case 2:
            DOBVerificationView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        case 3:
            GenderSelectionView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        case 4:
            SexualitySelectionView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        case 5:
            SexualityPreferenceView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        case 6:
            HeightSelectionView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        case 7:
            DatingIntentionView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        case 8:
            ChildrenFormView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        case 9:
            FamilyPlansView(isAuthenticated: $isAuthenticated, currentStep: $currentStep, hasChildren: false)
        case 10:
            EducationView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        case 11:
            ReligionView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        case 12:
            EthnicitySelectionView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        case 13:
            DrinkingHabitsView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        case 14:
            SmokingHabitsView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        case 15:
            PoliticalView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        case 16:
            DrugsView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        case 17:
            ProfilePicturesView(isAuthenticated: $isAuthenticated)
        case 18:
            ProgressView("Completing setup...")
        case 19:
            MainView(isAuthenticated: $isAuthenticated)
        default:
            UserProfileSetupView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        }
    }
}
