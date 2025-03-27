import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditOccupationView: View {
    @Binding var isAuthenticated: Bool
    @Binding var selectedTab: String
    @Binding var currentStep: Int
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var occupation = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    var isProfileSetup: Bool = false
    
    private let db = Firestore.firestore()
    
    // Comprehensive list of industries
    private let industries = [
        "Technology",
        "Healthcare",
        "Finance",
        "Education",
        "Engineering",
        "Legal",
        "Marketing",
        "Sales",
        "Manufacturing",
        "Retail",
        "Hospitality",
        "Transportation",
        "Construction",
        "Agriculture",
        "Energy",
        "Media",
        "Real Estate",
        "Government",
        "Non-Profit",
        "Military",
        "Arts & Entertainment",
        "Sports",
        "Fashion",
        "Food & Beverage",
        "Automotive",
        "Aerospace",
        "Pharmaceutical",
        "Telecommunications",
        "Environmental",
        "Other"
    ]
    
    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        if !isProfileSetup {
                            HStack {
                                Spacer()
                                Button(action: { dismiss() }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(Color("Gold"))
                                        .opacity(0.8)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color("Gold").opacity(0.1))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "briefcase.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color("Gold"))
                            }
                            
                            Text("Edit Industry")
                                .font(.custom("Lora-Regular", size: 24))
                                .foregroundColor(Color.accent)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 20)
                    }
                    
                    // Industry Selection
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What industry do you work in?")
                                .font(.custom("Lora-Regular", size: 18))
                                .foregroundColor(Color.accent)
                                .fontWeight(.medium)
                            
                            Text("Select the industry that best describes your work")
                                .font(.custom("Lora-Regular", size: 14))
                                .foregroundColor(Color.accent.opacity(0.7))
                        }
                        
                        Menu {
                            ForEach(industries, id: \.self) { industry in
                                Button(action: { occupation = industry }) {
                                    HStack {
                                        Text(industry)
                                        if occupation == industry {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(Color("Gold"))
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(occupation.isEmpty ? "Select an industry" : occupation)
                                    .foregroundColor(occupation.isEmpty ? Color.accent.opacity(0.5) : Color.accent)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(Color("Gold"))
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Save/Next button
                    VStack(spacing: 16) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(Color("Gold"))
                        } else {
                            Button(action: {
                                if isProfileSetup {
                                    saveAndContinue()
                                } else {
                                    saveChanges()
                                }
                            }) {
                                HStack {
                                    Text(isProfileSetup ? "Next" : "Save Changes")
                                        .font(.system(size: 17, weight: .semibold))
                                    if !occupation.isEmpty {
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(!occupation.isEmpty ? Color("Gold") : Color.gray.opacity(0.3))
                                        .shadow(color: !occupation.isEmpty ? Color("Gold").opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
                                )
                                .animation(.easeInOut(duration: 0.2), value: !occupation.isEmpty)
                            }
                            .disabled(occupation.isEmpty)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadUserIndustry()
            }
        }
    }
    
    private func loadUserIndustry() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error loading industry: \(error.localizedDescription)")
                return
            }
            
            if let document = document {
                DispatchQueue.main.async {
                    occupation = document.data()?["occupation"] as? String ?? ""
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
        
        db.collection("users").document(userId).updateData([
            "occupation": occupation
        ]) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving industry: \(error.localizedDescription)"
                showError = true
                return
            }
            
            // Dismiss the view after successful save
            dismiss()
        }
    }
    
    private func saveAndContinue() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Prevent multiple taps while saving
        guard !isLoading else { return }
        isLoading = true
        
        let data: [String: Any] = [
            "occupation": occupation
        ]
        
        db.collection("users").document(userId).updateData(data) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("Error saving occupation: \(error.localizedDescription)")
                }
                return
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
                if self.isProfileSetup {
                    self.appViewModel.updateProgress(.occupationComplete)
                    self.currentStep += 1
                } else {
                    self.selectedTab = "Profile"
                    self.dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditOccupationView(isAuthenticated: .constant(true), selectedTab: .constant("Profile"), currentStep: .constant(1))
    }
} 
