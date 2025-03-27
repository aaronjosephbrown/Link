//import SwiftUI
//import FirebaseFirestore
//import FirebaseAuth
//
//struct FinishProfileSetupView: View {
//    @Environment(\.dismiss) private var dismiss
//    @StateObject private var profileViewModel = ProfileViewModel()
//    @State private var currentSection = 0
//    @State private var isLoading = true
//    @State private var userName: String = ""
//    @State private var isAuthenticated: Bool = true
//    @State private var selectedTab: String = "0"
//    
//    private var bindings: (isAuthenticated: Binding<Bool>, selectedTab: Binding<String>, userName: Binding<String>) {
//        (
//            isAuthenticated: Binding(
//                get: { self.isAuthenticated },
//                set: { self.isAuthenticated = $0 }
//            ),
//            selectedTab: Binding(
//                get: { self.selectedTab },
//                set: { self.selectedTab = $0 }
//            ),
//            userName: Binding(
//                get: { self.userName },
//                set: { self.userName = $0 }
//            )
//        )
//    }
//    
//    var body: some View {
//        NavigationView {
//            BackgroundView {
//                VStack(spacing: 20) {
//                    if profileViewModel.incompleteFields.isEmpty {
//                        Text("All profile sections are complete!")
//                            .font(.title2)
//                            .foregroundColor(Color.accent)
//                            .padding()
//                        
//                        Button(action: { dismiss() }) {
//                            Text("Done")
//                                .font(.headline)
//                                .foregroundColor(.white)
//                                .frame(maxWidth: .infinity)
//                                .padding()
//                                .background(Color("Gold"))
//                                .cornerRadius(12)
//                        }
//                        .padding()
//                    } else {
//                        if isLoading {
//                            ProgressView()
//                                .scaleEffect(1.5)
//                                .tint(Color("Gold"))
//                        } else {
//                            // Section Content
//                            if currentSection < profileViewModel.incompleteFields.count {
//                                let incompleteField = profileViewModel.incompleteFields[currentSection]
//                                destinationView(for: incompleteField.field)
//                                    .padding(.bottom)
//                            }
//                        }
//                    }
//                }
//            }
//            .onAppear {
//                profileViewModel.updateProfileCompletion()
//                isLoading = false
//            }
//        }
//        .interactiveDismissDisabled()
//    }
//    
//    @ViewBuilder
//    private func destinationView(for field: String) -> some View {
//        switch field {
//        case "profileImage":
//            EditProfileImageView(userName: $userName, isAuthenticated: $isAuthenticated, selectedTab: $selectedTab, isProfileSetup: true)
//        case "gender":
//            EditGenderView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab, isProfileSetup: true)
//        case "sexuality":
//            EditSexualityView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab, isProfileSetup: true)
//        case "sexualityPreference":
//            EditSexualityPreferenceView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab, isProfileSetup: true)
//        case "datingIntention":
//            EditDatingIntentionView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab, isProfileSetup: true)
//        case "children":
//            EditChildrenView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab, isProfileSetup: true)
//        case "height":
//            EditHeightView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab, isProfileSetup: true)
//        case "education":
//            EditEducationView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab, isProfileSetup: true)
//        case "religion":
//            EditReligionView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab, isProfileSetup: true)
//        case "ethnicity":
//            EditEthnicityView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab, isProfileSetup: true)
//        case "drinking":
//            EditDrinkingView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab, isProfileSetup: true)
//        case "smokingHabits":
//            EditSmokingView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab, isProfileSetup: true)
//        case "politicalViews":
//            EditPoliticsView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab, isProfileSetup: true)
//        case "drugUse":
//            EditDrugsView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab, isProfileSetup: true)
//        case "bio":
//            EditBioView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab, isProfileSetup: true)
//        case "occupation":
//                EditOccupationView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab, currentStep: $currentStep, isProfileSetup: true)
//        case "activityLevel", "favoriteActivities", "preferSimilarFitness":
//            EditFitnessActivityView(isProfileSetup: true)
//        case "diet", "dietaryImportance", "dateDifferentDiet":
//            EditDietaryPreferencesView(isProfileSetup: true)
//        case "pets":
//            EditPetsAnimalsView(isProfileSetup: true)
//        case "bodyType", "heightPreference", "preferredPartnerHeight", "heightImportance":
//            EditAppearanceLifestyleView(isProfileSetup: true)
//        default:
//            EmptyView()
//        }
//    }
//    
//    private func moveToNextSection() {
//        if currentSection < profileViewModel.incompleteFields.count - 1 {
//            currentSection += 1
//        } else {
//            // All sections are complete
//            profileViewModel.updateProfileCompletion()
//            if profileViewModel.incompleteFields.isEmpty {
//                dismiss()
//            }
//        }
//    }
//}
//
//#Preview {
//    FinishProfileSetupView()
//} 
