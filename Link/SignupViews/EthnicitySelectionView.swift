import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EthnicitySelectionView: View {
    @Binding var isAuthenticated: Bool
    @Binding var currentStep: Int
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedEthnicity: String?
    @State private var selectedSubcategory: String?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSubcategoryVisible = false
    @State private var searchText = ""
    @State private var navigateToDrinking = false
    
    private let db = Firestore.firestore()
    
    private let ethnicityOptions = [
        "Black/African Descent",
        "White/Caucasian",
        "Asian",
        "Hispanic/Latino",
        "Middle Eastern",
        "Pacific Islander",
        "Native American",
        "Mixed",
        "Other"
    ]
    
    private let subcategories: [String: [String]] = [
        "Black/African Descent": [
            "Nigerian",
            "Ghanaian",
            "Ethiopian",
            "Kenyan",
            "South African",
            "Caribbean",
            "African American",
            "Other African Descent"
        ],
        "Asian": [
            "Chinese",
            "Japanese",
            "Korean",
            "Vietnamese",
            "Filipino",
            "Indian",
            "Pakistani",
            "Other Asian"
        ],
        "Hispanic/Latino": [
            "Mexican",
            "Puerto Rican",
            "Cuban",
            "Dominican",
            "Colombian",
            "Brazilian",
            "Other Hispanic/Latino"
        ]
    ]
    
    private var filteredEthnicities: [String] {
        if searchText.isEmpty {
            return ethnicityOptions
        }
        return ethnicityOptions.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color("Gold"))
                            .symbolEffect(.bounce, options: .repeating)
                        
                        Text("What's your ethnicity?")
                            .font(.custom("Lora-Regular", size: 24))
                            .foregroundColor(Color.accent)
                        
                        Text("Select your primary ethnicity")
                            .font(.custom("Lora-Regular", size: 16))
                            .foregroundColor(Color.accent.opacity(0.7))
                    }
                    .padding(.top, 40)
                    
                    // Progress indicator
                    SignupProgressView(currentStep: currentStep, totalSteps: 17)
                    
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.accent.opacity(0.5))
                        
                        TextField("", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.custom("Lora-Regular", size: 16))
                            .foregroundColor(Color.accent)
                            .placeholder(when: searchText.isEmpty) {
                                Text("Search for your ethnicity")
                                    .foregroundColor(Color.accent.opacity(0.5))
                                    .font(.custom("Lora-Regular", size: 16))
                            }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("Gold").opacity(0.1))
                    )
                    .padding(.horizontal)
                    
                    // Ethnicity selection
                    VStack(spacing: 24) {
                        // Main ethnicity grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(filteredEthnicities, id: \.self) { ethnicity in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedEthnicity = ethnicity
                                        selectedSubcategory = nil
                                        isSubcategoryVisible = subcategories[ethnicity] != nil
                                    }
                                }) {
                                    Text(ethnicity)
                                        .font(.custom("Lora-Regular", size: 14))
                                        .foregroundColor(selectedEthnicity == ethnicity ? .white : Color.accent)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 64)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedEthnicity == ethnicity ? Color("Gold") : Color("Gold").opacity(0.1))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedEthnicity == ethnicity ? Color("Gold") : Color("Gold").opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Subcategory selector (if applicable)
                        if let ethnicity = selectedEthnicity,
                           let options = subcategories[ethnicity] {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Select specific background")
                                    .font(.custom("Lora-Regular", size: 17))
                                    .foregroundColor(Color.accent)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(options, id: \.self) { subcategory in
                                            Button(action: {
                                                withAnimation(.spring(response: 0.3)) {
                                                    selectedSubcategory = subcategory
                                                }
                                            }) {
                                                HStack(spacing: 8) {
                                                    Text(subcategory)
                                                        .font(.custom("Lora-Regular", size: 15))
                                                        .foregroundColor(selectedSubcategory == subcategory ? .white : Color.accent)
                                                    
                                                    if selectedSubcategory == subcategory {
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 12, weight: .bold))
                                                    }
                                                }
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(
                                                    Capsule()
                                                        .fill(selectedSubcategory == subcategory ? Color("Gold") : Color("Gold").opacity(0.1))
                                                )
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Continue button
                    VStack(spacing: 16) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(1.2)
                        } else {
                            Button(action: saveAndContinue) {
                                HStack {
                                    Text("Continue")
                                        .font(.system(size: 17, weight: .semibold))
                                    
                                    if selectedEthnicity != nil {
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedEthnicity != nil ? Color("Gold") : Color.gray.opacity(0.3))
                                )
                                .animation(.easeInOut(duration: 0.2), value: selectedEthnicity != nil)
                            }
                            .disabled(selectedEthnicity == nil)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
                .padding()
                .navigationBarBackButtonHidden(true)
                .alert("Error", isPresented: $showError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(errorMessage)
                }
            }
        }
        .navigationDestination(isPresented: $navigateToDrinking) {
            DrinkingHabitsView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        }
    }
    
    private func saveAndContinue() {
        guard let ethnicity = selectedEthnicity else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        var userData: [String: Any] = [
            "ethnicity": ethnicity,
            "setupProgress": SignupProgress.ethnicityComplete.rawValue
        ]
        
        if let subcategory = selectedSubcategory {
            userData["ethnicitySubcategory"] = subcategory
        }
        
        db.collection("users").document(userId).updateData(userData) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving ethnicity: \(error.localizedDescription)"
                showError = true
                return
            }
            
            withAnimation {
                appViewModel.updateProgress(.ethnicityComplete)
                currentStep = 13
                navigateToDrinking = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        EthnicitySelectionView(
            isAuthenticated: .constant(false),
            currentStep: .constant(12)
        )
        .environmentObject(AppViewModel())
    }
    .preferredColorScheme(.light)
}

// Dark mode preview
#Preview("Dark Mode") {
    NavigationStack {
        EthnicitySelectionView(
            isAuthenticated: .constant(false),
            currentStep: .constant(12)
        )
        .environmentObject(AppViewModel())
    }
    .preferredColorScheme(.dark)
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
} 
