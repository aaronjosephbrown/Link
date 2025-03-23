import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileSetupFlowView: View {
    @Binding var isAuthenticated: Bool
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var currentStep = 0
    @State private var lastProgress: SignupProgress?
    
    var body: some View {
        NavigationStack {
            content
                .navigationBarBackButtonHidden(true)
                .transition(.slide)
        }
        .onAppear {
            initializeStep()
        }
        .onChange(of: appViewModel.getCurrentProgress()) { oldProgress, newProgress in
            // Only update if the progress has actually changed
            guard oldProgress != newProgress else { return }
            
            print("Progress changed from \(oldProgress) to \(newProgress)")
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = stepForProgress(newProgress)
                print("Current step updated to: \(currentStep)")
            }
        }
    }
    
    private func initializeStep() {
        let progress = appViewModel.getCurrentProgress()
        print("Initializing step with progress: \(progress)")
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = stepForProgress(progress)
            print("Initial step set to: \(currentStep)")
        }
    }
    
    private func stepForProgress(_ progress: SignupProgress) -> Int {
        let step: Int
        switch progress {
        case .initial:
            step = 0
        case .nameEntered:
            step = 1
        case .emailVerified:
            step = 2
        case .dobVerified:
            step = 3
        case .genderComplete:
            step = 4
        case .sexualityComplete:
            step = 5
        case .sexualityPreferenceComplete:
            step = 6
        case .heightComplete:
            step = 7
        case .datingIntentionComplete:
            step = 8
        case .childrenComplete:
            step = 9
        case .familyPlansComplete:
            step = 10
        case .educationComplete:
            step = 11
        case .religionComplete:
            step = 12
        case .ethnicityComplete:
            step = 13
        case .drinkingComplete:
            step = 14
        case .smokingComplete:
            step = 15
        case .politicsComplete:
            step = 16
        case .drugsComplete:
            step = 17
        case .locationComplete:
            step = 18
        case .photosComplete:
            step = 19
        case .complete:
            step = 20
        @unknown default:
            step = 0
        }
        print("Converting progress \(progress) to step \(step)")
        return step
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
            LocationPermissionView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        case 18:
            ProfilePicturesView(isAuthenticated: $isAuthenticated)
        case 19:
           ProgressView("Completing setup...")
        case 20:
           MainView(isAuthenticated: $isAuthenticated)
        default:
         UserProfileSetupView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        }
    }
}
