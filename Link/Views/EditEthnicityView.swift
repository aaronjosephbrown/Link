import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditEthnicityView: View {
    @Binding var isAuthenticated: Bool
    @Binding var selectedTab: String
    @State private var selectedEthnicity: String?
    @State private var selectedSubcategory: String?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSubcategoryVisible = false
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
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
                                    selectedEthnicity = option
                                    selectedSubcategory = nil
                                    isSubcategoryVisible = subcategories[option] != nil
                                }
                            }) {
                                HStack {
                                    Text(option)
                                        .font(.custom("Lora-Regular", size: 17))
                                        .foregroundColor(Color.accent)
                                    Spacer()
                                    if selectedEthnicity == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color("Gold"))
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedEthnicity == option ? Color("Gold") : Color("Gold").opacity(0.3), lineWidth: 2)
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
                    
                    Spacer()
                    
                    // Save button
                    VStack(spacing: 16) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(1.2)
                        } else {
                            Button(action: saveChanges) {
                                Text("Save Changes")
                                    .font(.system(size: 17, weight: .semibold))
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
                .navigationBarBackButtonHidden(false)
                .navigationBarItems(leading: 
                    Button(action: {
                        selectedTab = "Profile"
                        dismiss()
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
                DispatchQueue.main.async {
                    selectedEthnicity = document.data()?["ethnicity"] as? String
                    selectedSubcategory = document.data()?["ethnicitySubcategory"] as? String
                    isSubcategoryVisible = selectedEthnicity != nil && subcategories[selectedEthnicity!] != nil
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let ethnicity = selectedEthnicity else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        var userData: [String: Any] = ["ethnicity": ethnicity]
        
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
            
            selectedTab = "Profile"
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        EditEthnicityView(isAuthenticated: .constant(true), selectedTab: .constant("Profile"))
    }
}


