import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(Color.gray.opacity(0.3))
                
                Rectangle()
                    .foregroundColor(Color("Gold"))
                    .frame(width: geometry.size.width * progress)
            }
        }
        .frame(height: 4)
        .cornerRadius(2)
    }
}

struct ProfileSetupView: View {
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var currentStep = 0
    @State private var isAuthenticated = false
    @State private var selectedTab = "Profile"
    
    private var currentStepView: AnyView {
        switch currentStep {
        case 0:
            return AnyView(
                EditBasicInfoView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab, isProfileSetup: true)
                    .environmentObject(profileViewModel)
            )
        case 1:
            return AnyView(
                EditProfileImageView(userName: .constant(""), isAuthenticated: $isAuthenticated, selectedTab: $selectedTab, isProfileSetup: true)
                    .environmentObject(profileViewModel)
            )
        case 2:
            return AnyView(
                EditBioView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab, isProfileSetup: true)
                    .environmentObject(profileViewModel)
            )
        case 3:
            return AnyView(
                EditOccupationView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab, currentStep: $currentStep, isProfileSetup: true)
                    .environmentObject(profileViewModel)
            )
        case 4:
            return AnyView(
                EditAppearanceLifestyleView(isProfileSetup: true)
                    .environmentObject(profileViewModel)
            )
        case 5:
            return AnyView(
                EditFitnessActivityView(isProfileSetup: true)
                    .environmentObject(profileViewModel)
            )
        case 6:
            return AnyView(
                EditDietaryPreferencesView(isProfileSetup: true)
                    .environmentObject(profileViewModel)
            )
        case 7:
            return AnyView(
                EditPetsAnimalsView(isProfileSetup: true)
                    .environmentObject(profileViewModel)
            )
        default:
            return AnyView(EmptyView())
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                ProgressBar(progress: profileViewModel.profileCompletion)
                    .padding(.horizontal)
                    .padding(.top)
                
                // Current step view
                currentStepView
            }
            .navigationBarBackButtonHidden(true)
            .onChange(of: profileViewModel.shouldAdvanceToNextStep) { _, newValue in
                if newValue {
                    withAnimation {
                        currentStep += 1
                        profileViewModel.shouldAdvanceToNextStep = false
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileSetupView()
} 
