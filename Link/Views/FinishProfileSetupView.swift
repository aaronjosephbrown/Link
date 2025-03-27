import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FinishProfileSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var currentSection = 0
    @State private var heightPreference = ""
    @State private var bodyType = ""
    @State private var heightImportance: Double = 5
    @State private var preferredPartnerHeight = ""
    @State private var activityLevel = ""
    @State private var favoriteActivities: Set<String> = []
    @State private var preferSimilarFitness = false
    @State private var diet = ""
    @State private var dietaryImportance: Double = 5
    @State private var dateDifferentDiet = false
    @State private var hasPets = false
    @State private var petTypes: Set<String> = []
    @State private var dateWithPets = false
    @State private var animalPreference = ""
    @State private var heightNumberScale: CGFloat = 1.0
    @State private var dietaryNumberScale: CGFloat = 1.0
    @State private var heightNumberOpacity: Double = 1.0
    @State private var dietaryNumberOpacity: Double = 1.0
    @State private var isLoading = true
    @State private var bio: String = ""
    @State private var occupation: String = ""
    @State private var searchText = ""
    @State private var showOccupationPicker = false
    
    private let sections = ["Appearance & Lifestyle", "Fitness & Activity Level", "Dietary Preferences", "Pets & Animals", "Bio & Occupation"]
    private let bodyTypes = ["Athletic", "Slim", "Average", "Curvy", "Muscular", "Plus Size"]
    private let heightPreferences = ["Shorter", "Same height", "Taller", "No preference"]
    private let activityLevels = ["Sedentary", "Active", "Gym Regular", "Athlete"]
    private let activities = ["Hiking", "Yoga", "Gym", "Dance", "Team Sports", "Running", "Swimming", "Cycling"]
    private let diets = ["Omnivore", "Vegetarian", "Vegan", "Keto", "Paleo", "Mediterranean"]
    private let petTypesList = ["Dogs", "Cats", "Birds", "Fish", "Reptiles", "Other"]
    private let animalPreferences = ["Love animals", "Like animals", "Neutral", "Prefer no pets"]
    
    private let db = Firestore.firestore()
    
    private let industries = [
        "Accounting & Finance",
        "Advertising & Marketing",
        "Agriculture & Farming",
        "Architecture & Design",
        "Arts & Entertainment",
        "Automotive",
        "Aviation & Aerospace",
        "Banking & Financial Services",
        "Biotechnology & Pharmaceuticals",
        "Business & Consulting",
        "Construction & Real Estate",
        "Customer Service",
        "Education & Training",
        "Energy & Utilities",
        "Engineering",
        "Environmental & Sustainability",
        "Fashion & Apparel",
        "Food & Beverage",
        "Government & Public Service",
        "Healthcare & Medical",
        "Hospitality & Tourism",
        "Human Resources",
        "Information Technology",
        "Insurance",
        "Legal Services",
        "Manufacturing & Production",
        "Media & Communications",
        "Military & Defense",
        "Non-Profit & Social Services",
        "Personal Care & Wellness",
        "Real Estate",
        "Retail & Sales",
        "Science & Research",
        "Sports & Recreation",
        "Technology & Software",
        "Telecommunications",
        "Transportation & Logistics",
        "Veterinary Services",
        "Other"
    ]
    
    private var filteredIndustries: [String] {
        if searchText.isEmpty {
            return industries
        } else {
            return industries.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private enum ProfileSetupSection {
        case appearance
        case lifestyle
        case dietary
        case pets
        case bioAndOccupation
    }
    
    private var availableSections: [(title: String, section: ProfileSetupSection)] {
        var sections: [(String, ProfileSetupSection)] = []
        
        // Check each section's fields against incompleteFields
        if shouldShowSection(.appearance) {
            sections.append(("Appearance & Lifestyle", .appearance))
        }
        if shouldShowSection(.lifestyle) {
            sections.append(("Fitness & Activity Level", .lifestyle))
        }
        if shouldShowSection(.dietary) {
            sections.append(("Dietary Preferences", .dietary))
        }
        if shouldShowSection(.pets) {
            sections.append(("Pets & Animals", .pets))
        }
        if shouldShowSection(.bioAndOccupation) {
            sections.append(("Bio & Occupation", .bioAndOccupation))
        }
        
        return sections
    }
    
    var body: some View {
        NavigationView {
            BackgroundView {
                VStack(spacing: 20) {
                    if availableSections.isEmpty {
                        Text("All profile sections are complete!")
                            .font(.title2)
                            .foregroundColor(Color.accent)
                            .padding()
                        
                        Button(action: { dismiss() }) {
                            Text("Done")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("Gold"))
                                .cornerRadius(12)
                        }
                        .padding()
                    } else {
                        // Progress Bar
                        if !availableSections.isEmpty {
                            ProgressView(value: Double(min(currentSection, availableSections.count - 1)), 
                                       total: Double(max(1, availableSections.count - 1)))
                                .tint(Color("Gold"))
                                .padding(.horizontal)
                        }
                        
                        // Section Title
                        if currentSection < availableSections.count {
                            Text(availableSections[currentSection].title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color.accent)
                                .padding(.top)
                        }
                        
                        if isLoading {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(Color("Gold"))
                        } else {
                            // Section Content
                            ScrollView {
                                VStack(spacing: 24) {
                                    if currentSection < availableSections.count {
                                        switch availableSections[currentSection].section {
                                        case .appearance:
                                            appearanceSection
                                        case .lifestyle:
                                            fitnessSection
                                        case .dietary:
                                            dietarySection
                                        case .pets:
                                            petsSection
                                        case .bioAndOccupation:
                                            bioAndOccupationSection
                                        }
                                    }
                                }
                                .padding()
                            }
                        }
                        
                        // Navigation Buttons
                        HStack(spacing: 20) {
                            if currentSection > 0 {
                                Button(action: { currentSection -= 1 }) {
                                    Text("Back")
                                        .font(.headline)
                                        .foregroundColor(Color.accent)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color("Gold").opacity(0.1))
                                        .cornerRadius(12)
                                }
                            }
                            
                            Button(action: {
                                if currentSection < availableSections.count - 1 {
                                    currentSection += 1
                                } else {
                                    saveProfileSetup()
                                }
                            }) {
                                Text(currentSection < availableSections.count - 1 ? "Next" : "Finish")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color("Gold"))
                                    .cornerRadius(12)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarItems(leading: Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .foregroundColor(Color("Gold"))
            })
            .onAppear {
                loadExistingData()
                // Reset currentSection if it's out of bounds
                if currentSection >= availableSections.count {
                    currentSection = 0
                }
            }
        }
        .interactiveDismissDisabled()
    }
    
    private func loadExistingData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error loading profile setup: \(error.localizedDescription)")
                isLoading = false
                return
            }
            
            if let document = document {
                let data = document.data() ?? [:]
                
                heightPreference = data["heightPreference"] as? String ?? ""
                bodyType = data["bodyType"] as? String ?? ""
                heightImportance = data["heightImportance"] as? Double ?? 5
                preferredPartnerHeight = data["preferredPartnerHeight"] as? String ?? ""
                activityLevel = data["activityLevel"] as? String ?? ""
                favoriteActivities = Set(data["favoriteActivities"] as? [String] ?? [])
                preferSimilarFitness = data["preferSimilarFitness"] as? Bool ?? false
                diet = data["diet"] as? String ?? ""
                dietaryImportance = data["dietaryImportance"] as? Double ?? 5
                dateDifferentDiet = data["dateDifferentDiet"] as? Bool ?? false
                hasPets = data["hasPets"] as? Bool ?? false
                petTypes = Set(data["petTypes"] as? [String] ?? [])
                dateWithPets = data["dateWithPets"] as? Bool ?? false
                animalPreference = data["animalPreference"] as? String ?? ""
                bio = data["bio"] as? String ?? ""
                occupation = data["occupation"] as? String ?? ""
                
                // Update profile view model with current data
                profileViewModel.updateProfileCompletion()
            }
            isLoading = false
        }
    }
    
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Height & Body Type Preferences")
                .font(.headline)
                .foregroundColor(Color.accent)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Describe your body type")
                    .foregroundColor(Color.accent)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(bodyTypes, id: \.self) { type in
                            Button(action: { bodyType = type }) {
                                Text(type)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(bodyType == type ? Color("Gold") : Color("Gold").opacity(0.1))
                                    .foregroundColor(bodyType == type ? .white : Color.accent)
                                    .cornerRadius(20)
                            }
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("How important is height in a match?")
                    .foregroundColor(Color.accent)
                Slider(value: $heightImportance, in: 1...10, step: 1)
                    .tint(Color("Gold"))
                HStack {
                    Text("Not at all")
                    Spacer()
                    Text("\(Int(heightImportance))")
                        .fontWeight(.bold)
                        .foregroundColor(Color("Gold"))
                        .scaleEffect(heightNumberScale)
                        .opacity(heightNumberOpacity)
                        .onChange(of: heightImportance) { _ , _ in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                heightNumberScale = 1.3
                                heightNumberOpacity = 0.7
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    heightNumberScale = 1.0
                                    heightNumberOpacity = 1.0
                                }
                            }
                        }
                    Spacer()
                    Text("Very important")
                }
                .font(.caption)
                .foregroundColor(Color.accent.opacity(0.7))
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Preferred partner's height")
                    .foregroundColor(Color.accent)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(heightPreferences, id: \.self) { preference in
                            Button(action: { preferredPartnerHeight = preference }) {
                                Text(preference)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(preferredPartnerHeight == preference ? Color("Gold") : Color("Gold").opacity(0.1))
                                    .foregroundColor(preferredPartnerHeight == preference ? .white : Color.accent)
                                    .cornerRadius(20)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var fitnessSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Fitness & Activity Level")
                .font(.headline)
                .foregroundColor(Color.accent)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("How would you describe your activity level?")
                    .foregroundColor(Color.accent)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(activityLevels, id: \.self) { level in
                            Button(action: { activityLevel = level }) {
                                Text(level)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(activityLevel == level ? Color("Gold") : Color("Gold").opacity(0.1))
                                    .foregroundColor(activityLevel == level ? .white : Color.accent)
                                    .cornerRadius(20)
                            }
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Favorite ways to stay active")
                    .foregroundColor(Color.accent)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(activities, id: \.self) { activity in
                            Button(action: {
                                if favoriteActivities.contains(activity) {
                                    favoriteActivities.remove(activity)
                                } else {
                                    favoriteActivities.insert(activity)
                                }
                            }) {
                                Text(activity)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(favoriteActivities.contains(activity) ? Color("Gold") : Color("Gold").opacity(0.1))
                                    .foregroundColor(favoriteActivities.contains(activity) ? .white : Color.accent)
                                    .cornerRadius(20)
                            }
                        }
                    }
                }
            }
            
            Toggle("Would you prefer a partner with a similar fitness level?", isOn: $preferSimilarFitness)
                .foregroundColor(Color.accent)
                .tint(Color("Gold"))
        }
    }
    
    private var dietarySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Dietary Preferences")
                .font(.headline)
                .foregroundColor(Color.accent)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("What best describes your diet?")
                    .foregroundColor(Color.accent)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(diets, id: \.self) { dietType in
                            Button(action: { diet = dietType }) {
                                Text(dietType)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(diet == dietType ? Color("Gold") : Color("Gold").opacity(0.1))
                                    .foregroundColor(diet == dietType ? .white : Color.accent)
                                    .cornerRadius(20)
                            }
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("How important is dietary compatibility?")
                    .foregroundColor(Color.accent)
                Slider(value: $dietaryImportance, in: 1...10, step: 1)
                    .tint(Color("Gold"))
                HStack {
                    Text("Not at all")
                    Spacer()
                    Text("\(Int(dietaryImportance))")
                        .fontWeight(.bold)
                        .foregroundColor(Color("Gold"))
                        .scaleEffect(dietaryNumberScale)
                        .opacity(dietaryNumberOpacity)
                        .onChange(of: dietaryImportance) { _ , _ in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                dietaryNumberScale = 1.3
                                dietaryNumberOpacity = 0.7
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    dietaryNumberScale = 1.0
                                    dietaryNumberOpacity = 1.0
                                }
                            }
                        }
                    Spacer()
                    Text("Very")
                }
                .font(.caption)
                .foregroundColor(Color.accent.opacity(0.7))
            }
            
            Toggle("Would you date someone with different eating habits?", isOn: $dateDifferentDiet)
                .foregroundColor(Color.accent)
                .tint(Color("Gold"))
        }
    }
    
    private var petsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Pets & Animals")
                .font(.headline)
                .foregroundColor(Color.accent)
            
            Toggle("Do you have pets?", isOn: $hasPets)
                .foregroundColor(Color.accent)
                .tint(Color("Gold"))
            
            if hasPets {
                VStack(alignment: .leading, spacing: 12) {
                    Text("What types of pets do you have?")
                        .foregroundColor(Color.accent)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(petTypesList, id: \.self) { type in
                                Button(action: {
                                    if petTypes.contains(type) {
                                        petTypes.remove(type)
                                    } else {
                                        petTypes.insert(type)
                                    }
                                }) {
                                    Text(type)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(petTypes.contains(type) ? Color("Gold") : Color("Gold").opacity(0.1))
                                        .foregroundColor(petTypes.contains(type) ? .white : Color.accent)
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }
                }
            }
            
            Toggle("Would you date someone with pets?", isOn: $dateWithPets)
                .foregroundColor(Color.accent)
                .tint(Color("Gold"))
            
            VStack(alignment: .leading, spacing: 12) {
                Text("How do you feel about animals?")
                    .foregroundColor(Color.accent)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(animalPreferences, id: \.self) { preference in
                            Button(action: { animalPreference = preference }) {
                                Text(preference)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(animalPreference == preference ? Color("Gold") : Color("Gold").opacity(0.1))
                                    .foregroundColor(animalPreference == preference ? .white : Color.accent)
                                    .cornerRadius(20)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var bioAndOccupationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Bio & Occupation")
                .font(.headline)
                .foregroundColor(Color.accent)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Tell us about yourself")
                    .foregroundColor(Color.accent)
                ZStack(alignment: .topLeading) {
                    if bio.isEmpty {
                        Text("Write something about yourself...")
                            .foregroundColor(.gray)
                            .padding(.leading, 12)
                            .padding(.top, 16)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $bio)
                        .frame(height: 200)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("What industry do you work in?")
                    .foregroundColor(Color.accent)
                
                Button(action: { showOccupationPicker = true }) {
                    HStack {
                        Text(occupation.isEmpty ? "Select your industry" : occupation)
                            .foregroundColor(occupation.isEmpty ? .gray : Color.accent)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(Color("Gold"))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                    )
                }
            }
        }
        .sheet(isPresented: $showOccupationPicker) {
            NavigationView {
                VStack {
                    // Search bar
                    TextField("Search industries...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    // Industry list
                    List(filteredIndustries, id: \.self) { industry in
                        Button(action: {
                            occupation = industry
                            searchText = "" // Reset search text
                            showOccupationPicker = false
                        }) {
                            HStack {
                                Text(industry)
                                    .foregroundColor(Color.accent)
                                Spacer()
                                if occupation == industry {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color("Gold"))
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Select Industry")
                .navigationBarItems(trailing: Button("Cancel") {
                    searchText = "" // Reset search text
                    showOccupationPicker = false
                })
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled()
            .onDisappear {
                searchText = "" // Reset search text when sheet is dismissed
            }
        }
    }
    
    private func saveProfileSetup() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Ensure all required fields have valid values
        let profileData: [String: Any] = [
            "heightPreference": heightPreference.isEmpty ? "No preference" : heightPreference,
            "bodyType": bodyType.isEmpty ? "Average" : bodyType,
            "heightImportance": heightImportance,
            "preferredPartnerHeight": preferredPartnerHeight.isEmpty ? "No preference" : preferredPartnerHeight,
            "activityLevel": activityLevel,
            "favoriteActivities": Array(favoriteActivities),
            "preferSimilarFitness": preferSimilarFitness,
            "diet": diet,
            "dietaryImportance": dietaryImportance,
            "dateDifferentDiet": dateDifferentDiet,
            "hasPets": hasPets,
            "petTypes": Array(petTypes),
            "dateWithPets": dateWithPets,
            "animalPreference": animalPreference,
            "bio": bio,
            "occupation": occupation,
            "profileSetupCompleted": true
        ]
        
        isLoading = true
        
        db.collection("users").document(userId).updateData(profileData) { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    print("Error saving profile setup: \(error.localizedDescription)")
                } else {
                    // Update profile view model to reflect changes
                    profileViewModel.updateProfileCompletion()
                    // Only dismiss after successful save
                    dismiss()
                }
            }
        }
    }
    
    private func shouldShowSection(_ section: ProfileSetupSection) -> Bool {
        switch section {
        case .appearance:
            // Only show if any of these fields are empty or have default values
            return bodyType.isEmpty || 
                   heightPreference.isEmpty || 
                   preferredPartnerHeight.isEmpty ||
                   bodyType == "Select your body type" ||
                   heightPreference == "Select your height preference" ||
                   preferredPartnerHeight == "Select preferred height"
            
        case .lifestyle:
            // Only show if activity level is empty or favorite activities is empty
            return activityLevel.isEmpty || favoriteActivities.isEmpty
            
        case .dietary:
            // Only show if diet is empty
            return diet.isEmpty
            
        case .pets:
            // Only show if any of these fields are empty or have default values
            return animalPreference.isEmpty || (hasPets && petTypes.isEmpty)
            
        case .bioAndOccupation:
            // Only show if either bio or occupation is empty
            return bio.isEmpty || occupation.isEmpty
        }
    }
}

#Preview {
    FinishProfileSetupView()
} 
