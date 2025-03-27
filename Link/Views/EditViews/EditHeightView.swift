import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditHeightView: View {
    @Binding var isAuthenticated: Bool
    @Binding var selectedTab: String
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var heightFeet = 5
    @State private var heightInches = 8
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isPickerVisible = false
    var isProfileSetup: Bool = false
    
    private let db = Firestore.firestore()
    
    private let feetRange = Array(4...7)
    private let inchesRange = Array(0...11)
    
    private var formattedHeight: String {
        "\(heightFeet)'\(heightInches)\""
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
                        Image(systemName: "ruler.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color("Gold"))
                            .padding(.bottom, 8)
                        Text("Edit Height")
                            .font(.custom("Lora-Regular", size: 19))
                            .foregroundColor(Color.accent)
                    }
                    .padding(.top, 40)
                    
                    // Height picker
                    VStack(spacing: 20) {
                        // Height display
                        Text(formattedHeight)
                            .font(.custom("Lora-Regular", size: 72))
                            .foregroundColor(Color.accent)
                            .padding(.vertical, 20)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3), value: formattedHeight)
                        
                        // Height selector button
                        Button(action: { withAnimation { isPickerVisible.toggle() } }) {
                            HStack(spacing: 12) {
                                Text("\(heightFeet) ft \(heightInches) in")
                                    .font(.custom("Lora-Regular", size: 17))
                                    .foregroundColor(Color.accent)
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color("Gold"))
                                    .rotationEffect(.degrees(isPickerVisible ? 180 : 0))
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("Gold").opacity(0.3), lineWidth: 2)
                            )
                        }
                        
                        if isPickerVisible {
                            VStack(spacing: 16) {
                                // Feet selector
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Feet")
                                        .font(.custom("Lora-Regular", size: 15))
                                        .foregroundColor(Color.accent.opacity(0.7))
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(feetRange, id: \.self) { feet in
                                                Button(action: { heightFeet = feet }) {
                                                    Text("\(feet)'")
                                                        .font(.custom("Lora-Regular", size: 17))
                                                        .foregroundColor(heightFeet == feet ? .white : Color.accent)
                                                        .padding(.horizontal, 20)
                                                        .padding(.vertical, 10)
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 8)
                                                                .fill(heightFeet == feet ? Color("Gold") : Color("Gold").opacity(0.1))
                                                        )
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 4)
                                    }
                                }
                                
                                // Inches selector
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Inches")
                                        .font(.custom("Lora-Regular", size: 15))
                                        .foregroundColor(Color.accent.opacity(0.7))
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(inchesRange, id: \.self) { inches in
                                                Button(action: { heightInches = inches }) {
                                                    Text("\(inches)\"")
                                                        .font(.custom("Lora-Regular", size: 17))
                                                        .foregroundColor(heightInches == inches ? .white : Color.accent)
                                                        .padding(.horizontal, 20)
                                                        .padding(.vertical, 10)
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 8)
                                                                .fill(heightInches == inches ? Color("Gold") : Color("Gold").opacity(0.1))
                                                        )
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 4)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                    
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
                                HStack {
                                    Text(isProfileSetup ? "Next" : "Save Changes")
                                        .font(.system(size: 17, weight: .semibold))
                                    if isProfileSetup {
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color("Gold"))
                                )
                            }
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
                    loadUserHeight()
                }
            }
        }
    }
    
    private func loadUserHeight() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error loading height: \(error.localizedDescription)")
                return
            }
            
            if let document = document,
               let height = document.data()?["height"] as? String {
                DispatchQueue.main.async {
                    // Parse the height string (e.g., "5'8\"")
                    let components = height.components(separatedBy: CharacterSet(charactersIn: "'\""))
                    if components.count >= 2,
                       let feet = Int(components[0]),
                       let inches = Int(components[1]) {
                        heightFeet = feet
                        heightInches = inches
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
        
        db.collection("users").document(userId).updateData([
            "height": formattedHeight
        ]) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving height: \(error.localizedDescription)"
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
        
        let heightInInches = (heightFeet * 12) + heightInches
        
        let data: [String: Any] = [
            "height": heightInInches
        ]
        
        db.collection("users").document(userId).updateData(data) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("Error saving height: \(error.localizedDescription)")
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
        EditHeightView(isAuthenticated: .constant(true), selectedTab: .constant("Profile"))
    }
} 