import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditEthnicityView: View {
    @Binding var isAuthenticated: Bool
    @Binding var selectedTab: String
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var ethnicity = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var searchText = ""
    @State private var selectedSubcategory: String?
    var isProfileSetup: Bool = false
    
    private let ethnicities = [
        "Asian",
        "Black/African",
        "Hispanic/Latino",
        "Middle Eastern",
        "Native American",
        "Pacific Islander",
        "White/Caucasian",
        "Mixed",
        "Other",
        "Prefer not to say"
    ]
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
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        if !isProfileSetup {
                            HStack {
                                Spacer()
                                Button(action: { dismiss() }) {
                                    Image(systemName: "xmark")
                                        .font(.title2)
                                        .foregroundColor(Color("Gold"))
                                }
                            }
                        }
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color("Gold"))
                            .padding(.bottom, 8)
                        Text("Edit Ethnicity")
                            .font(.custom("Lora-Regular", size: 19))
                            .foregroundColor(Color.accent)
                    }
                    .padding(.top, 40)
                    
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
                    
                    // Ethnicity options
                    VStack(spacing: 12) {
                        ForEach(filteredEthnicities, id: \.self) { option in
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    ethnicity = option
                                }
                            }) {
                                HStack {
                                    Text(option)
                                        .font(.custom("Lora-Regular", size: 17))
                                        .foregroundColor(Color.accent)
                                    Spacer()
                                    if ethnicity == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color("Gold"))
                                            .font(.system(size: 20))
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(ethnicity == option ? Color("Gold") : Color("Gold").opacity(0.3), lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Subcategory selector (if applicable)
                    if let options = subcategories[ethnicity] {
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
                    
                    Spacer()
                    
                    // Save/Next button
                    VStack(spacing: 16) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(1.2)
                        } else {
                            Button(action: {
                                if isProfileSetup {
                                    saveAndContinue()
                                } else {
                                    saveChanges()
                                }
                            }) {
                                Text(isProfileSetup ? "Next" : "Save Changes")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(ethnicity.isEmpty ? Color.gray.opacity(0.3) : Color("Gold"))
                                    )
                            }
                            .disabled(ethnicity.isEmpty)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
                .padding()
                .navigationBarBackButtonHidden(false)
                .navigationBarItems(leading: 
                    Button(action: {
                        if isProfileSetup {
                            dismiss()
                        } else {
                            selectedTab = "Profile"
                            dismiss()
                        }
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .foregroundColor(Color("Gold"))
                            Text("Back")
                                .foregroundColor(Color("Gold"))
                        }
                    }
                )
                .alert("Error", isPresented: $showError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(errorMessage)
                }
                .onAppear {
                    loadUserEthnicity()
                }
            }
        }
    }
    
    private func loadUserEthnicity() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error loading ethnicity: \(error.localizedDescription)")
                return
            }
            
            if let document = document {
                let data = document.data() ?? [:]
                if let ethnicity = data["ethnicity"] as? String {
                    DispatchQueue.main.async {
                        self.ethnicity = ethnicity
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        let data: [String: Any] = [
            "ethnicity": ethnicity
        ]
        
        db.collection("users").document(userId).updateData(data) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving ethnicity: \(error.localizedDescription)"
                showError = true
                return
            }
            
            selectedTab = "Profile"
            dismiss()
        }
    }
    
    private func saveAndContinue() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Prevent multiple taps while saving
        guard !isLoading else { return }
        isLoading = true
        
        let data: [String: Any] = [
            "ethnicity": ethnicity
        ]
        
        db.collection("users").document(userId).updateData(data) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("Error saving ethnicity: \(error.localizedDescription)")
                }
                return
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
                if self.isProfileSetup {
                    self.profileViewModel.shouldAdvanceToNextStep = true
                } else {
                    self.dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditEthnicityView(isAuthenticated: .constant(true), selectedTab: .constant("Profile"))
    }
}


