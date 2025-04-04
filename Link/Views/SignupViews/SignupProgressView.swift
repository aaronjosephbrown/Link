import SwiftUI

struct SignupProgressView: View {
    let currentStep: Int
    let totalSteps: Int = 19
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(index <= currentStep ? Color("Gold") : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    SignupProgressView(currentStep: 2)
} 
