import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditHeightView: View {
    @Binding var isAuthenticated: Bool
    @Binding var selectedTab: String
    @State private var selectedFeet = 5
    @State private var selectedInches = 8
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isPickerVisible = false
    @Environment(\.dismiss) private var dismiss
    
    private let db = Firestore.firestore()
    
    private let feetRange = Array(4...7)
    private let inchesRange = Array(0...11)
    
    private var formattedHeight: String {
        "\(selectedFeet)'\(selectedInches)\""
    }
    
    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "ruler")
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
                                Text("\(selectedFeet) ft \(selectedInches) in")
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
                                                Button(action: { selectedFeet = feet }) {
                                                    Text("\(feet)'")
                                                        .font(.custom("Lora-Regular", size: 17))
                                                        .foregroundColor(selectedFeet == feet ? .white : Color.accent)
                                                        .padding(.horizontal, 20)
                                                        .padding(.vertical, 10)
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 8)
                                                                .fill(selectedFeet == feet ? Color("Gold") : Color("Gold").opacity(0.1))
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
                                                Button(action: { selectedInches = inches }) {
                                                    Text("\(inches)\"")
                                                        .font(.custom("Lora-Regular", size: 17))
                                                        .foregroundColor(selectedInches == inches ? .white : Color.accent)
                                                        .padding(.horizontal, 20)
                                                        .padding(.vertical, 10)
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 8)
                                                                .fill(selectedInches == inches ? Color("Gold") : Color("Gold").opacity(0.1))
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
                                            .fill(Color("Gold"))
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: true)
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
                        selectedFeet = feet
                        selectedInches = inches
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
}

#Preview {
    NavigationStack {
        EditHeightView(isAuthenticated: .constant(true), selectedTab: .constant("Profile"))
    }
} 