import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct ProfileView: View {
    @Binding var userName: String
    @Binding var isAuthenticated: Bool
    @Binding var selectedTab: String
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @State private var profileImageUrl: String?
    @State private var isLoadingImage = false
    @State private var selectedSection = 0
    @State private var showEditProfile = false
    @State private var showGetMore = false
    @State private var showSafety = false
    @State private var showEditProfileImages = false
    @State private var showPremium = false
    @State private var showBoost = false
    @State private var showRoses = false
    @State private var showSettings = false
    @State private var showLogoutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showDeleteConfirmationAlert = false
    @State private var showDeleteSuccessAlert = false
    @State private var showDeleteErrorAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showPremiumSheet = false
    @State private var showBoostSheet = false
    @State private var showRosesSheet = false
    @State private var showLogoutSheet = false
    @State private var showDeleteAccountSheet = false
    @State private var showDeleteConfirmationSheet = false
    @State private var showDeleteSuccessSheet = false
    @State private var showDeleteErrorSheet = false
    @State private var showErrorSheet = false
    @State private var showEditProfileImagesSheet = false
    @State private var showEditProfileImagesFullScreen = false
    @State private var showEditGender = false
    @State private var showEditSexuality = false
    @State private var showEditDatingIntention = false
    @State private var showEditChildren = false
    @State private var showEditFamilyPlans = false
    @State private var localProfileImage: UIImage?
    @State private var showEditHeight = false
    @State private var showEditSexualityPreference = false
    @State private var showEditEducation = false
    @State private var showEditReligion = false
    @State private var showEditEthnicity = false
    @State private var showEditDrinking = false
    @State private var showEditSmoking = false
    @State private var showEditPolitics = false
    @State private var showEditDrugs = false
    @State private var showFinishProfileSetup = false
    @State private var profileSetupCompleted = false
    @State private var showAppearanceLifestyle = false
    @State private var showFitnessActivity = false
    @State private var showDietaryPreferences = false
    @State private var showPetsAnimals = false
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    var body: some View {
        NavigationStack {
            BackgroundView {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Profile Header
                        HStack {
                            Text("Lumé")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color.accent)
                            Spacer()
                            Button(action: {}) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.title2)
                                    .foregroundColor(Color("Gold"))
                            }
                            Button(action: { showSettings = true }) {
                                Image(systemName: "gearshape")
                                    .font(.title2)
                                    .foregroundColor(Color("Gold"))
                            }
                        }
                        .padding(.horizontal)
                        
                        // Profile Picture with Completion Ring
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                                .frame(width: 120, height: 120)
                                .padding(.bottom)
                            
                            Circle()
                                .trim(from: 0, to: profileViewModel.profileCompletion)
                                .stroke(Color("Gold"), lineWidth: 8)
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                                .padding(.bottom)
                            
                            if isLoadingImage {
                                ProgressView()
                                    .frame(width: 110, height: 110)
                                    .padding(.bottom)
                            } else if let localImage = localProfileImage {
                                Image(uiImage: localImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 110, height: 110)
                                    .clipShape(Circle())
                                    .padding(.bottom)
                            } else if let imageUrl = profileImageUrl {
                                AsyncImage(url: URL(string: imageUrl)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 110, height: 110)
                                        .clipShape(Circle())
                                        .padding(.bottom)
                                } placeholder: {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 110, height: 110)
                                        .padding(.bottom)
                                }
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 110, height: 110)
                                    .padding(.bottom)
                            }
                            
                            if profileViewModel.profileCompletion >= 1.0 {
                                Text("Complete")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.accent)
                                    .offset(y: 70)
                            } else {
                                Text("\(Int(profileViewModel.profileCompletion * 100))%")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.accent)
                                    .offset(y: 70)
                                    .padding([.top, .bottom], 30)
                            }
                        }
                        
                        // Name and Verification
                        HStack {
                            Text(userName)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.accent)
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(Color("Gold"))
                        }
                        
                        Text("Incomplete profile")
                            .foregroundColor(Color.accent.opacity(0.7))
                        
                        if !profileSetupCompleted {
                            // Finish Profile Setup Button
                            Button(action: { showFinishProfileSetup = true }) {
                                Text("Finish Profile Setup")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color("Gold"))
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .fullScreenCover(isPresented: $showFinishProfileSetup) {
                                FinishProfileSetupView()
                            }
                        }
                        
                        // Navigation Tabs
                        HStack(spacing: 0) {
                                Button(action: { selectedSection = 0 }) {
                                Text("Get more")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                        .foregroundColor(selectedSection == 0 ? Color("Gold") : Color.accent)
                            }
                            
                                Button(action: { selectedSection = 1 }) {
                                Text("Safety")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                        .foregroundColor(selectedSection == 1 ? Color("Gold") : Color.accent)
                            }
                            
                            Button(action: { selectedSection = 2 }) {
                                Text("Edit")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .foregroundColor(selectedSection == 2 ? Color("Gold") : Color.accent)
                            }
                        }
                        .background(Color("Gold").opacity(0.1))
                        
                        // Paging TabView
                        TabView(selection: $selectedSection) {
                            // Get More View
                            GetMoreView()
                                .tag(0)
                            
                            // Safety View
                            SafetyView()
                                .tag(1)
                            
                            // Edit Section View
                            ScrollView(showsIndicators: false) {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Edit")
                                        .font(.headline)
                                        .foregroundColor(Color.accent)
                                        .padding(.horizontal)
                                    
                                    if !profileSetupCompleted {
                                        Button(action: { showFinishProfileSetup = true }) {
                                            HStack {
                                                Image(systemName: "checkmark.circle")
                                                    .foregroundColor(Color("Gold"))
                                                Text("Complete Profile Setup")
                                                    .foregroundColor(Color.accent)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(Color("Gold"))
                                            }
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                                            )
                                        }
                                    }
                                    
                                    VStack(spacing: 12) {
                                        Button(action: {
                                            showEditProfileImagesFullScreen = true
                                        }) {
                                            HStack {
                                                Image(systemName: "photo.circle")
                                                    .foregroundColor(Color("Gold"))
                                                Text("Profile Image")
                                                    .foregroundColor(Color.accent)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(Color("Gold"))
                                            }
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                                            )
                                        }
                                        
                                        Button(action: {
                                            showEditGender = true
                                        }) {
                                            HStack {
                                                Image(systemName: "person.2.circle")
                                                    .foregroundColor(Color("Gold"))
                                                Text("Gender")
                                                    .foregroundColor(Color.accent)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(Color("Gold"))
                                            }
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                                            )
                                        }
                                        
                                        Button(action: {
                                            showEditSexuality = true
                                        }) {
                                            HStack {
                                                Image(systemName: "heart.circle")
                                                    .foregroundColor(Color("Gold"))
                                                Text("Sexuality")
                                                    .foregroundColor(Color.accent)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(Color("Gold"))
                                            }
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                                            )
                                        }
                                        
                                        Button(action: {
                                            showEditDatingIntention = true
                                        }) {
                                            HStack {
                                                Image(systemName: "star.circle")
                                                    .foregroundColor(Color("Gold"))
                                                Text("Dating Intention")
                                                    .foregroundColor(Color.accent)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(Color("Gold"))
                                            }
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                                            )
                                        }
                                        
                                        Button(action: {
                                            showEditChildren = true
                                        }) {
                                            HStack {
                                                Image(systemName: "person.circle")
                                                    .foregroundColor(Color("Gold"))
                                                Text("Children")
                                                    .foregroundColor(Color.accent)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(Color("Gold"))
                                            }
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                                            )
                                        }
                                        
                                        Button(action: {
                                            showEditFamilyPlans = true
                                        }) {
                                            HStack {
                                                Image(systemName: "house.circle")
                                                    .foregroundColor(Color("Gold"))
                                                Text("Family Plans")
                                                    .foregroundColor(Color.accent)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(Color("Gold"))
                                            }
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                                            )
                                        }
                                        
                                        Button(action: {
                                            showEditHeight = true
                                        }) {
                                            HStack {
                                                Image(systemName: "ruler")
                                                    .foregroundColor(Color("Gold"))
                                                Text("Height")
                                                    .foregroundColor(Color.accent)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(Color("Gold"))
                                            }
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                                            )
                                        }
                                        
                                        Button(action: {
                                            showEditSexualityPreference = true
                                        }) {
                                            HStack {
                                                Image(systemName: "heart.text.square")
                                                    .foregroundColor(Color("Gold"))
                                                Text("Sexuality Preference")
                                                    .foregroundColor(Color.accent)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(Color("Gold"))
                                            }
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                                            )
                                        }
                                        
                                        Button(action: {
                                            showEditEducation = true
                                        }) {
                                            HStack {
                                                Image(systemName: "book.circle")
                                                    .foregroundColor(Color("Gold"))
                                                Text("Education")
                                                    .foregroundColor(Color.accent)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(Color("Gold"))
                                            }
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                                            )
                                        }
                                        
                                        Button(action: {
                                            showEditReligion = true
                                        }) {
                                            HStack {
                                                Image(systemName: "sparkles")
                                                    .foregroundColor(Color("Gold"))
                                                Text("Religion")
                                                    .foregroundColor(Color.accent)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(Color("Gold"))
                                            }
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                                            )
                                        }
                                        
                                        Button(action: {
                                            showEditEthnicity = true
                                        }) {
                                            HStack {
                                                Image(systemName: "globe")
                                                    .foregroundColor(Color("Gold"))
                                                Text("Ethnicity")
                                                    .foregroundColor(Color.accent)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(Color("Gold"))
                                            }
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                                            )
                                        }
                                        
                                        Button(action: {
                                            showEditDrinking = true
                                        }) {
                                            HStack {
                                                Image(systemName: "wineglass")
                                                    .foregroundColor(Color("Gold"))
                                                Text("Drinking")
                                                    .foregroundColor(Color.accent)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(Color("Gold"))
                                            }
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                                            )
                                        }
                                        
                                        Button(action: {
                                            showEditSmoking = true
                                        }) {
                                            HStack {
                                                Image(systemName: "smoke")
                                                    .foregroundColor(Color("Gold"))
                                                Text("Smoking")
                                                    .foregroundColor(Color.accent)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(Color("Gold"))
                                            }
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                                            )
                                        }
                                        
                                        Button(action: {
                                            showEditPolitics = true
                                        }) {
                                            HStack {
                                                Image(systemName: "building.columns")
                                                    .foregroundColor(Color("Gold"))
                                                Text("Politics")
                                                    .foregroundColor(Color.accent)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(Color("Gold"))
                                            }
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                                            )
                                        }
                                        
                                        Button(action: {
                                            showEditDrugs = true
                                        }) {
                                            HStack {
                                                Image(systemName: "pills")
                                                    .foregroundColor(Color("Gold"))
                                                Text("Drugs")
                                                    .foregroundColor(Color.accent)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(Color("Gold"))
                                            }
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                                            )
                                        }
                                        
                                        // Profile Setup Section
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Profile Setup")
                                                .font(.headline)
                                                .foregroundColor(Color.accent)
                                                .padding(.top)
                                            
                                            Button(action: { showAppearanceLifestyle = true }) {
                                                HStack {
                                                    Image(systemName: "person.2")
                                                        .foregroundColor(Color("Gold"))
                                                    Text("Appearance & Lifestyle")
                                                        .foregroundColor(Color.accent)
                                                    Spacer()
                                                    Image(systemName: "chevron.right")
                                                        .foregroundColor(Color("Gold"))
                                                }
                                                .padding()
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                                                )
                                            }
                                            
                                            Button(action: { showFitnessActivity = true }) {
                                                HStack {
                                                    Image(systemName: "figure.run")
                                                        .foregroundColor(Color("Gold"))
                                                    Text("Fitness & Activity Level")
                                                        .foregroundColor(Color.accent)
                                                    Spacer()
                                                    Image(systemName: "chevron.right")
                                                        .foregroundColor(Color("Gold"))
                                                }
                                                .padding()
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                                                )
                                            }
                                            
                                            Button(action: { showDietaryPreferences = true }) {
                                                HStack {
                                                    Image(systemName: "fork.knife")
                                                        .foregroundColor(Color("Gold"))
                                                    Text("Dietary Preferences")
                                                        .foregroundColor(Color.accent)
                                                    Spacer()
                                                    Image(systemName: "chevron.right")
                                                        .foregroundColor(Color("Gold"))
                                                }
                                                .padding()
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                                                )
                                            }
                                            
                                            Button(action: { showPetsAnimals = true }) {
                                                HStack {
                                                    Image(systemName: "pawprint")
                                                        .foregroundColor(Color("Gold"))
                                                    Text("Pets & Animals")
                                                        .foregroundColor(Color.accent)
                                                    Spacer()
                                                    Image(systemName: "chevron.right")
                                                        .foregroundColor(Color("Gold"))
                                                }
                                                .padding()
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                                                )
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                }
                                .padding(.vertical)
                            }
                            .frame(maxHeight: .infinity)
                            .background(Color("Gold").opacity(0.05))
                            .tag(2)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: 400)
                        .background(Color("Gold").opacity(0.05))
                    }
                    .padding(.vertical)
                }
                .onAppear {
                    loadProfilePicture()
                    checkProfileCompletion()
                }
            }
            .fullScreenCover(isPresented: $showEditProfileImagesFullScreen) {
                EditProfileImageView(
                    userName: $userName,
                    isAuthenticated: $isAuthenticated,
                    selectedTab: $selectedTab,
                    onProfileImagesUpdated: {
                        loadProfilePicture()
                    }
                )
            }
            .fullScreenCover(isPresented: $showEditGender) {
                EditGenderView(
                    isAuthenticated: $isAuthenticated,
                    selectedTab: $selectedTab
                )
            }
            .fullScreenCover(isPresented: $showEditSexuality) {
                EditSexualityView(
                    isAuthenticated: $isAuthenticated,
                    selectedTab: $selectedTab
                )
            }
            .fullScreenCover(isPresented: $showEditDatingIntention) {
                EditDatingIntentionView(
                    isAuthenticated: $isAuthenticated,
                    selectedTab: $selectedTab
                )
            }
            .fullScreenCover(isPresented: $showEditChildren) {
                EditChildrenView(
                    isAuthenticated: $isAuthenticated,
                    selectedTab: $selectedTab
                )
            }
            .fullScreenCover(isPresented: $showEditFamilyPlans) {
                EditFamilyPlansView(
                    isAuthenticated: $isAuthenticated,
                    selectedTab: $selectedTab
                )
            }
            .fullScreenCover(isPresented: $showEditHeight) {
                EditHeightView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab)
            }
            .fullScreenCover(isPresented: $showEditSexualityPreference) {
                EditSexualityPreferenceView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab)
            }
            .fullScreenCover(isPresented: $showEditEducation) {
                EditEducationView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab)
            }
            .fullScreenCover(isPresented: $showEditReligion) {
                EditReligionView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab)
            }
            .fullScreenCover(isPresented: $showEditEthnicity) {
                EditEthnicityView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab)
            }
            .fullScreenCover(isPresented: $showEditDrinking) {
                EditDrinkingView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab)
            }
            .fullScreenCover(isPresented: $showEditSmoking) {
                EditSmokingView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab)
            }
            .fullScreenCover(isPresented: $showEditPolitics) {
                EditPoliticsView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab)
            }
            .fullScreenCover(isPresented: $showEditDrugs) {
                EditDrugsView(isAuthenticated: $isAuthenticated, selectedTab: $selectedTab)
            }
            .fullScreenCover(isPresented: $showAppearanceLifestyle) {
                AppearanceLifestyleView()
            }
            .fullScreenCover(isPresented: $showFitnessActivity) {
                FitnessActivityView()
            }
            .fullScreenCover(isPresented: $showDietaryPreferences) {
                DietaryPreferencesView()
            }
            .fullScreenCover(isPresented: $showPetsAnimals) {
                PetsAnimalsView()
            }
            .fullScreenCover(isPresented: $showSettings) {
                SettingsView(isAuthenticated: $isAuthenticated)
            }
        }
    }
    
    private func loadProfilePicture() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoadingImage = true
        
        // First try to load from local storage
        if let localImage = ImageStorageManager.shared.loadImage(for: userId, at: 0) {
            localProfileImage = localImage
            isLoadingImage = false
            return
        }
        
        // If not found locally, load from Firestore
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error loading profile: \(error.localizedDescription)")
                isLoadingImage = false
                return
            }
            
            if let document = document,
               let profilePictures = document.data()?["profilePictures"] as? [String],
               let firstPicture = profilePictures.first {
                profileImageUrl = firstPicture
            }
            isLoadingImage = false
        }
    }
    
    private func checkProfileCompletion() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error checking profile completion: \(error.localizedDescription)")
                return
            }
            
            if let document = document {
                let data = document.data() ?? [:]
                profileSetupCompleted = data["profileSetupCompleted"] as? Bool ?? false
                
                // Calculate profile completion percentage
                var completedFields = 0
                var totalFields = 0
                
                // Profile Pictures (6 required)
                if let photos = data["profilePictures"] as? [String] {
                    completedFields += min(photos.count, 6)
                    totalFields += 6
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
                                completedFields += 1
                            }
                        } else if let string = value as? String, !string.isEmpty {
                            completedFields += 1
                        }
                    }
                    totalFields += 1
                }
                
                let newCompletion = Double(completedFields) / Double(totalFields)
                profileViewModel.profileCompletion = newCompletion
            }
        }
    }
}

struct GetMoreView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                    // Premium Promotion
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Premium")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Get seen sooner and go on 3x as many dates")
                            .foregroundColor(.white)
                        
                        Button(action: {}) {
                            Text("Upgrade")
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .frame(width: 120)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .cornerRadius(20)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("Gold"))
                    )
                    .padding(.horizontal)
                    
                    // Boost Section
                    HStack {
                        Circle()
                            .fill(Color("Gold"))
                            .frame(width: 50, height: 50)
                            .overlay(
                                ZStack {
                                    Image(systemName: "bolt.fill")
                                        .foregroundColor(.white)
                                    Text("0")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .offset(x: 15, y: -15)
                                }
                            )
                        
                        VStack(alignment: .leading) {
                            Text("Boost")
                                .font(.headline)
                                .foregroundColor(Color.accent)
                            Text("Get seen by 11X more people")
                                .font(.subheadline)
                                .foregroundColor(Color.accent.opacity(0.7))
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color("Gold").opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Roses Section
                    HStack {
                        Circle()
                            .fill(Color("Gold"))
                            .frame(width: 50, height: 50)
                            .overlay(
                                ZStack {
                                    Image(systemName: "rosette")
                                        .foregroundColor(.white)
                                    Text("0")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .offset(x: 15, y: -15)
                                }
                            )
                        
                        VStack(alignment: .leading) {
                            Text("Roses")
                                .font(.headline)
                                .foregroundColor(Color.accent)
                            Text("2x as likely to lead to a date")
                                .font(.subheadline)
                                .foregroundColor(Color.accent.opacity(0.7))
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color("Gold").opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

struct SafetyView: View {
    var body: some View {
        VStack {
            Text("Safety View")
                .font(.title)
                .foregroundColor(Color.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("Gold").opacity(0.05))
    }
}

struct SettingsView: View {
    @Binding var isAuthenticated: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        BackgroundView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Settings")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color.accent)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(Color("Gold"))
                    }
                }
                .padding()
                
                // Settings Options
                VStack(spacing: 16) {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "bell")
                                .foregroundColor(Color("Gold"))
                            Text("Notifications")
                                .foregroundColor(Color.accent)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color("Gold"))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                        )
                    }
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(Color("Gold"))
                            Text("Privacy")
                                .foregroundColor(Color.accent)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color("Gold"))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                        )
                    }
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(Color("Gold"))
                            Text("Help & Support")
                                .foregroundColor(Color.accent)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color("Gold"))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                        )
                    }
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(Color("Gold"))
                            Text("Terms of Service")
                                .foregroundColor(Color.accent)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color("Gold"))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                        )
                    }
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "hand.raised")
                                .foregroundColor(Color("Gold"))
                            Text("Privacy Policy")
                                .foregroundColor(Color.accent)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color("Gold"))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                        )
                    }
                    
                    Button(action: signOut) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(Color("Gold"))
                        Text("Sign Out")
                                .foregroundColor(Color.accent)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color("Gold"))
                        }
                            .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView(userName: .constant("Preview User"), isAuthenticated: .constant(true), selectedTab: .constant("Profile"))
            .environmentObject(ProfileViewModel())
    }
} 
