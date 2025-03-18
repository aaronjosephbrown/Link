import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct DOBVerificationView: View {
    @Binding var isAuthenticated: Bool
    @Binding var currentStep: Int
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var month = ""
    @State private var day = ""
    @State private var year = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var focusedField: DateField?
    
    private let db = Firestore.firestore()
    private let calendar = Calendar.current
    private let minimumAge = 18
    
    private enum DateField {
        case month, day, year
    }
    
    private var dateInputIsValid: Bool {
        guard let monthInt = Int(month),
              let dayInt = Int(day),
              let yearInt = Int(year),
              monthInt > 0, monthInt <= 12,
              dayInt > 0, dayInt <= 31,
              yearInt >= 1900, yearInt <= calendar.component(.year, from: Date()) else {
            return false
        }
        
        let dateComponents = DateComponents(year: yearInt, month: monthInt, day: dayInt)
        guard let date = calendar.date(from: dateComponents),
              calendar.isDate(date, equalTo: date, toGranularity: .day) else {
            return false
        }
        
        return true
    }
    
    private var dateValidationMessage: String {
        if month.isEmpty || day.isEmpty || year.isEmpty {
            return "Please fill in all date fields"
        }
        if !dateInputIsValid {
            return "Please enter a valid date"
        }
        return ""
    }
    
    private var isAgeValid: Bool {
        guard dateInputIsValid,
              let monthInt = Int(month),
              let dayInt = Int(day),
              let yearInt = Int(year) else {
            return false
        }
        
        let dateComponents = DateComponents(year: yearInt, month: monthInt, day: dayInt)
        guard let birthDate = calendar.date(from: dateComponents) else {
            return false
        }
        
        let age = calendar.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        return age >= minimumAge
    }
    
    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color("Gold"))
                            .symbolEffect(.bounce, options: .repeating)
                        
                        Text("Verify Your Age")
                            .font(.custom("Lora-Regular", size: 24))
                            .foregroundColor(Color.accent)
                        
                        Text("You must be at least \(minimumAge) years old to use Link")
                            .font(.custom("Lora-Regular", size: 16))
                            .foregroundColor(Color.accent.opacity(0.7))
                    }
                    .padding(.top, 40)
                    
                    // Progress indicator
                    SignupProgressView(currentStep: currentStep, totalSteps: 17)
                    
                    // Date form
                    VStack(spacing: 24) {
                        HStack(spacing: 12) {
                            // Month Field
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Month")
                                    .font(.custom("Lora-Regular", size: 19))
                                    .foregroundColor(Color.accent.opacity(0.7))
                                TextField("", text: $month)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.custom("Lora-Regular", size: 17))
                                    .foregroundColor(Color.accent)
                                    .keyboardType(.numberPad)
                                    .frame(width: 80)
                                    .focused($focusedField, equals: .month)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 8)
                                    .background(
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(focusedField == .month ? Color("Gold").opacity(0.3) : Color("Gold"), lineWidth: 2)
                                            if month.isEmpty {
                                                Text("MM")
                                                    .font(.custom("Lora-Regular", size: 17))
                                                    .foregroundColor(Color.accent.opacity(0.5))
                                                    .padding(.leading, 8)
                                            }
                                        }
                                    )
                                    .onChange(of: month) { _, newValue in
                                        if newValue.count > 2 {
                                            month = String(newValue.prefix(2))
                                        }
                                        if let monthInt = Int(newValue) {
                                            if monthInt > 12 {
                                                month = "12"
                                            }
                                            if monthInt > 0 && newValue.count == 2 {
                                                focusedField = .day
                                            }
                                        }
                                    }
                            }
                            
                            // Day Field
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Day")
                                    .font(.custom("Lora-Regular", size: 19))
                                    .foregroundColor(Color.accent.opacity(0.7))
                                TextField("", text: $day)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.custom("Lora-Regular", size: 17))
                                    .foregroundColor(Color.accent)
                                    .keyboardType(.numberPad)
                                    .frame(width: 80)
                                    .focused($focusedField, equals: .day)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 8)
                                    .background(
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(focusedField == .day ? Color("Gold").opacity(0.3) : Color("Gold"), lineWidth: 2)
                                            if day.isEmpty {
                                                Text("DD")
                                                    .font(.custom("Lora-Regular", size: 17))
                                                    .foregroundColor(Color.accent.opacity(0.5))
                                                    .padding(.leading, 8)
                                            }
                                        }
                                    )
                                    .onChange(of: day) { _, newValue in
                                        if newValue.count > 2 {
                                            day = String(newValue.prefix(2))
                                        }
                                        if let dayInt = Int(newValue) {
                                            if dayInt > 31 {
                                                day = "31"
                                            }
                                            if dayInt > 0 && newValue.count == 2 {
                                                focusedField = .year
                                            }
                                        }
                                    }
                            }
                            
                            // Year Field
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Year")
                                    .font(.custom("Lora-Regular", size: 19))
                                    .foregroundColor(Color.accent.opacity(0.7))
                                TextField("", text: $year)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.custom("Lora-Regular", size: 17))
                                    .foregroundColor(Color.accent)
                                    .keyboardType(.numberPad)
                                    .frame(width: 100)
                                    .focused($focusedField, equals: .year)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 8)
                                    .background(
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(focusedField == .year ? Color("Gold").opacity(0.3) : Color("Gold"), lineWidth: 2)
                                            if year.isEmpty {
                                                Text("YYYY")
                                                    .font(.custom("Lora-Regular", size: 17))
                                                    .foregroundColor(Color.accent.opacity(0.5))
                                                    .padding(.leading, 8)
                                            }
                                        }
                                    )
                                    .onChange(of: year) { _ , newValue in
                                        if newValue.count > 4 {
                                            year = String(newValue.prefix(4))
                                        }
                                        if newValue.count == 4 {
                                            focusedField = nil // Dismiss keyboard
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        if !dateInputIsValid {
                            Text(dateValidationMessage)
                                .font(.custom("Lora-Regular", size: 14))
                                .foregroundColor(.accentColor)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Continue button
                    VStack(spacing: 16) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(1.2)
                        } else {
                            Button(action: verifyAge) {
                                HStack {
                                    Text("Continue")
                                        .font(.system(size: 17, weight: .semibold))
                                    
                                    if isAgeValid {
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(isAgeValid ? Color("Gold") : Color.gray.opacity(0.3))
                                )
                                .animation(.easeInOut(duration: 0.2), value: isAgeValid)
                            }
                            .disabled(!isAgeValid)
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
    }
    
    private func verifyAge() {
        guard isAgeValid,
              let monthInt = Int(month),
              let dayInt = Int(day),
              let yearInt = Int(year) else { return }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        isLoading = true
        
        let dateComponents = DateComponents(year: yearInt, month: monthInt, day: dayInt)
        guard let birthDate = calendar.date(from: dateComponents) else {
            errorMessage = "Invalid date"
            showError = true
            isLoading = false
            return
        }
        
        let userData: [String: Any] = [
            "dateOfBirth": birthDate,
            "setupProgress": SignupProgress.dobVerified.rawValue
        ]
        
        db.collection("users").document(userId).updateData(userData) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error saving date of birth: \(error.localizedDescription)"
                showError = true
                return
            }
            
            withAnimation {
                appViewModel.updateProgress(.dobVerified)
                currentStep = 3
            }
        }
    }
}

#Preview {
    NavigationStack {
        DOBVerificationView(
            isAuthenticated: .constant(false),
            currentStep: .constant(2)
        )
        .environmentObject(AppViewModel())
    }
    .preferredColorScheme(.light)
}

// Dark mode preview
#Preview("Dark Mode") {
    NavigationStack {
        DOBVerificationView(
            isAuthenticated: .constant(false),
            currentStep: .constant(2)
        )
        .environmentObject(AppViewModel())
    }
    .preferredColorScheme(.dark)
} 
