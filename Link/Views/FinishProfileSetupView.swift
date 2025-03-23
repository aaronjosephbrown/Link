import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FinishProfileSetupView: View {
    @Environment(\.dismiss) private var dismiss
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
    @State private var hasPets = ""
    @State private var petTypes: Set<String> = []
    @State private var dateWithPets = false
    @State private var animalPreference = ""
    @State private var heightNumberScale: CGFloat = 1.0
    @State private var dietaryNumberScale: CGFloat = 1.0
    @State private var heightNumberOpacity: Double = 1.0
    @State private var dietaryNumberOpacity: Double = 1.0
    @State private var isLoading = true
    
    private let sections = ["Appearance & Lifestyle", "Fitness & Activity Level", "Dietary Preferences", "Pets & Animals"]
    private let bodyTypes = ["Athletic", "Slim", "Average", "Curvy", "Muscular", "Plus Size"]
    private let heightPreferences = ["Shorter", "Same height", "Taller", "No preference"]
    private let activityLevels = ["Sedentary", "Active", "Gym Regular", "Athlete"]
    private let activities = ["Hiking", "Yoga", "Gym", "Dance", "Team Sports", "Running", "Swimming", "Cycling"]
    private let diets = ["Omnivore", "Vegetarian", "Vegan", "Keto", "Paleo", "Mediterranean"]
    private let petOptions = ["Dog", "Cat", "Snake", "Other"]
    private let animalPreferences = ["Love them", "Indifferent", "Prefer a pet-free space"]
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            BackgroundView {
                VStack(spacing: 20) {
                    // Progress Bar
                    ProgressView(value: Double(currentSection), total: Double(sections.count - 1))
                        .tint(Color("Gold"))
                        .padding(.horizontal)
                    
                    // Section Title
                    Text(sections[currentSection])
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.accent)
                        .padding(.top)
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(Color("Gold"))
                    } else {
                        // Section Content
                        ScrollView {
                            VStack(spacing: 24) {
                                switch currentSection {
                                case 0:
                                    appearanceSection
                                case 1:
                                    fitnessSection
                                case 2:
                                    dietarySection
                                case 3:
                                    petsSection
                                default:
                                    EmptyView()
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
                            if currentSection < sections.count - 1 {
                                currentSection += 1
                            } else {
                                saveProfileSetup()
                            }
                        }) {
                            Text(currentSection < sections.count - 1 ? "Next" : "Finish")
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
            .navigationBarItems(leading: Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .foregroundColor(Color("Gold"))
            })
            .onAppear {
                loadExistingData()
            }
        }
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
                hasPets = data["hasPets"] as? String ?? ""
                petTypes = Set(data["petTypes"] as? [String] ?? [])
                dateWithPets = data["dateWithPets"] as? Bool ?? false
                animalPreference = data["animalPreference"] as? String ?? ""
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
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Do you have pets?")
                    .foregroundColor(Color.accent)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(petOptions, id: \.self) { pet in
                            Button(action: {
                                if petTypes.contains(pet) {
                                    petTypes.remove(pet)
                                } else {
                                    petTypes.insert(pet)
                                }
                            }) {
                                Text(pet)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(petTypes.contains(pet) ? Color("Gold") : Color("Gold").opacity(0.1))
                                    .foregroundColor(petTypes.contains(pet) ? .white : Color.accent)
                                    .cornerRadius(20)
                            }
                        }
                    }
                }
            }
            
            Toggle("Would you date someone with pets?", isOn: $dateWithPets)
                .foregroundColor(Color.accent)
                .tint(Color("Gold"))
            
            VStack(alignment: .leading, spacing: 12) {
                Text("How do you feel about animals in the home?")
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
    
    private func saveProfileSetup() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let profileData: [String: Any] = [
            "heightPreference": heightPreference,
            "bodyType": bodyType,
            "heightImportance": heightImportance,
            "preferredPartnerHeight": preferredPartnerHeight,
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
            "profileSetupCompleted": true
        ]
        
        db.collection("users").document(userId).updateData(profileData) { error in
            if let error = error {
                print("Error saving profile setup: \(error.localizedDescription)")
            } else {
                dismiss()
            }
        }
    }
}

#Preview {
    FinishProfileSetupView()
} 
