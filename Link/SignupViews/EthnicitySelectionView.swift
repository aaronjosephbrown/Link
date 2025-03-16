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
    @State private var showSubcategories = false
    @State private var navigateToChildren = false
    
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
    
    var body: some View {
        VStack(spacing: 20) {
            if showSubcategories {
                subcategoryView
            } else {
                mainEthnicityView
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .navigationDestination(isPresented: $navigateToChildren) {
            ChildrenFormView(isAuthenticated: $isAuthenticated, currentStep: $currentStep)
        }
    }
    
    private var mainEthnicityView: some View {
        VStack(spacing: 20) {
            Text("What's your ethnicity?")
                .font(.title)
                .padding(.top)
            
            Text("Select your ethnicity")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            SignupProgressView(currentStep: 12, totalSteps: 17)
                .padding(.vertical, 20)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(ethnicityOptions, id: \.self) { ethnicity in
                        Button(action: { selectEthnicity(ethnicity) }) {
                            HStack {
                                Text(ethnicity)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedEthnicity == ethnicity {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                                if subcategories[ethnicity] != nil {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedEthnicity == ethnicity ? Color.blue.opacity(0.1) : Color(.systemGray6))
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            if isLoading {
                ProgressView()
            } else {
                Button(action: saveEthnicityAndContinue) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedEthnicity != nil ? Color.blue : Color.gray)
                        )
                }
                .disabled(selectedEthnicity == nil)
                .padding(.horizontal)
            }
        }
    }
    
    private var subcategoryView: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: { showSubcategories = false }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
                Spacer()
            }
            .padding(.horizontal)
            
            Text("Specify your background")
                .font(.title)
                .padding(.top)
            
            Text("Select your specific ethnicity")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            if let ethnicity = selectedEthnicity,
               let options = subcategories[ethnicity] {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(options, id: \.self) { subcategory in
                            Button(action: { selectedSubcategory = subcategory }) {
                                HStack {
                                    Text(subcategory)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if selectedSubcategory == subcategory {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedSubcategory == subcategory ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                } else {
                    Button(action: saveSubcategoryAndContinue) {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedSubcategory != nil ? Color.blue : Color.gray)
                            )
                    }
                    .disabled(selectedSubcategory == nil)
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func selectEthnicity(_ ethnicity: String) {
        selectedEthnicity = ethnicity
        selectedSubcategory = nil
        
        if subcategories[ethnicity] != nil {
            showSubcategories = true
        }
    }
    
    private func saveEthnicityAndContinue() {
        guard let ethnicity = selectedEthnicity else { return }
        
        // If this ethnicity has subcategories, don't save yet
        if subcategories[ethnicity] != nil {
            showSubcategories = true
            return
        }
        
        saveToFirestore(ethnicity: ethnicity, subcategory: nil)
    }
    
    private func saveSubcategoryAndContinue() {
        guard let ethnicity = selectedEthnicity,
              let subcategory = selectedSubcategory else { return }
        
        saveToFirestore(ethnicity: ethnicity, subcategory: subcategory)
    }
    
    private func saveToFirestore(ethnicity: String, subcategory: String?) {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        var userData: [String: Any] = [
            "ethnicity": ethnicity,
            "setupProgress": "ethnicity_complete"
        ]
        
        if let subcategory = subcategory {
            userData["ethnicitySubcategory"] = subcategory
        }
        
        db.collection("users").document(userId).updateData(userData) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving ethnicity: \(error.localizedDescription)"
                showError = true
                return
            }
            
            currentStep = 13
        }
    }
}

#Preview {
    NavigationView {
        EthnicitySelectionView(isAuthenticated: .constant(true), currentStep: .constant(0))
            .environmentObject(AppViewModel())
    }
} 
