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
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Verify Your Age")
                .font(.title)
                .padding(.top)
            
            Text("You must be at least \(minimumAge) years old to use Link")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            SignupProgressView(currentStep: 2, totalSteps: 17)
                .padding(.vertical, 20)
            
            Text("Date of Birth")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                // Month Field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Month")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("MM", text: $month)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .frame(width: 80)
                        .focused($focusedField, equals: .month)
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
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("DD", text: $day)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .frame(width: 80)
                        .focused($focusedField, equals: .day)
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
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("YYYY", text: $year)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .frame(width: 100)
                        .focused($focusedField, equals: .year)
                        .onChange(of: year) { _, newValue in
                            if newValue.count > 4 {
                                year = String(newValue.prefix(4))
                            }
                            if newValue.count == 4 {
                                focusedField = nil // Dismiss keyboard
                            }
                        }
                }
            }
            .padding(.horizontal)
            
            if !dateInputIsValid {
                Text(dateValidationMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            if isLoading {
                ProgressView()
            } else {
                Button(action: verifyAge) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isAgeValid ? Color.blue : Color.gray)
                        )
                }
                .disabled(!isAgeValid)
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Age Verification")
        .navigationBarBackButtonHidden(true)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
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
            
            appViewModel.updateProgress(.dobVerified)
            currentStep = 3
        }
    }
}

#Preview {
    NavigationView {
        DOBVerificationView(
            isAuthenticated: .constant(true),
            currentStep: .constant(2)
        )
        .environmentObject(AppViewModel())
    }
} 
