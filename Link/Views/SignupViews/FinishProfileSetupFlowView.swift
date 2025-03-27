import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FinishProfileSetupFlowView: View {
    @Binding var isAuthenticated: Bool
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    
    var body: some View {
        NavigationStack {
            content
                .navigationBarBackButtonHidden(true)
                .transition(.slide)
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch currentStep {
        case 0:
            EditFitnessActivityView(isProfileSetup: true)
                .onChange(of: profileViewModel.shouldAdvanceToNextStep) { _, shouldAdvance in
                    if shouldAdvance {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep += 1
                        }
                        profileViewModel.shouldAdvanceToNextStep = false
                    }
                }
        case 1:
            EditDietaryPreferencesView(isProfileSetup: true)
                .onChange(of: profileViewModel.shouldAdvanceToNextStep) { _, shouldAdvance in
                    if shouldAdvance {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep += 1
                        }
                        profileViewModel.shouldAdvanceToNextStep = false
                    }
                }
        case 2:
            EditPetsAnimalsView(isProfileSetup: true)
                .onChange(of: profileViewModel.shouldAdvanceToNextStep) { _, shouldAdvance in
                    if shouldAdvance {
                        // When complete, dismiss and return to MainView
                        dismiss()
                    }
                }
        default:
            EmptyView()
        }
    }
}

#Preview {
    FinishProfileSetupFlowView(isAuthenticated: .constant(true))
        .environmentObject(ProfileViewModel())
} 
