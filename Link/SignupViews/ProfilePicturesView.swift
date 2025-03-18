import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

struct ProfilePicturesView: View {
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showPhotoPicker = false
    @State private var uploadTasks: [StorageUploadTask] = []
    @Binding var isAuthenticated: Bool
    @EnvironmentObject var appViewModel: AppViewModel
    
    private let requiredPhotoCount = 6
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "photo.stack.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color("Gold"))
                            .padding(.bottom, 8)
                        
                        Text("Pick your videos and photos")
                            .font(.custom("Lora-Regular", size: 19))
                            .foregroundColor(Color.accent)
                    }
                    .padding(.top, 40)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(0..<requiredPhotoCount, id: \.self) { index in
                            if index < selectedImages.count {
                                Image(uiImage: selectedImages[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color("Gold"), style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    )
                                    .onTapGesture {
                                        showPhotoPicker = true
                                    }
                            } else {
                                Button(action: {
                                    showPhotoPicker = true
                                }) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color("Gold"), style: StrokeStyle(lineWidth: 2, dash: [5]))
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            Image(systemName: "plus")
                                                .foregroundColor(Color("Gold"))
                                                .font(.system(size: 30))
                                        )
                                }
                            }
                        }
                    }
                    .padding()
                    
                    VStack(spacing: 8) {
                        Text("Tap to edit, drag to reorder")
                            .font(.custom("Lora-Regular", size: 15))
                            .foregroundColor(Color.accent)
                        Text("\(requiredPhotoCount) required")
                            .font(.custom("Lora-Regular", size: 15))
                            .foregroundColor(Color.accent)
                    }
                    
                    Spacer()
                    
                    // Continue button
                    VStack(spacing: 16) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(1.2)
                        } else if selectedImages.count == requiredPhotoCount {
                            Button(action: uploadPhotos) {
                                HStack {
                                    Text("Continue")
                                        .font(.system(size: 17, weight: .semibold))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color("Gold"))
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
                .padding()
            }
            .photosPicker(isPresented: $showPhotoPicker,
                         selection: $selectedItems,
                         maxSelectionCount: requiredPhotoCount,
                         matching: .images)
            .onChange(of: selectedItems) { _ , _ in
                Task {
                    selectedImages = []
                    for item in selectedItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            selectedImages.append(image)
                        }
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onDisappear {
                // Cancel any ongoing uploads when the view disappears
                for task in uploadTasks {
                    task.cancel()
                }
                uploadTasks.removeAll()
            }
        }
    }
    
    private func uploadPhotos() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            showError = true
            return
        }
        
        isLoading = true
        let group = DispatchGroup()
        var uploadedUrls: [String] = []
        
        // Clear any existing upload tasks
        for task in uploadTasks {
            task.cancel()
        }
        uploadTasks.removeAll()
        
        for (index, image) in selectedImages.enumerated() {
            group.enter()
            
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                group.leave()
                continue
            }
            
            let filename = "\(userId)_\(index)_\(UUID().uuidString).jpg"
            let storageRef = storage.reference().child("profile_pictures/\(userId)/\(filename)")
            
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            let uploadTask = storageRef.putData(imageData, metadata: metadata) { _, error in
                if let error = error {
                    errorMessage = "Upload failed: \(error.localizedDescription)"
                    showError = true
                    group.leave()
                    return
                }
                
                storageRef.downloadURL { url, error in
                    if let error = error {
                        errorMessage = "Failed to get download URL: \(error.localizedDescription)"
                        showError = true
                        group.leave()
                        return
                    }
                    
                    if let urlString = url?.absoluteString {
                        uploadedUrls.append(urlString)
                    }
                    group.leave()
                }
            }
            
            uploadTasks.append(uploadTask)
        }
        
        group.notify(queue: .main) {
            if uploadedUrls.count == requiredPhotoCount {
                savePhotoUrlsToFirestore(urls: uploadedUrls, userId: userId)
            } else {
                errorMessage = "Not all photos were uploaded successfully"
                showError = true
                isLoading = false
            }
        }
    }
    
    private func savePhotoUrlsToFirestore(urls: [String], userId: String) {
        db.collection("users").document(userId).updateData([
            "profilePictures": urls,
            "setupProgress": SignupProgress.photosComplete.rawValue
        ]) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Failed to save photo URLs: \(error.localizedDescription)"
                showError = true
            } else {
                withAnimation {
                    appViewModel.updateProgress(.complete)
                    isAuthenticated = true
                }
            }
        }
    }
}

#Preview {
    ProfilePicturesView(isAuthenticated: .constant(false))
        .environmentObject(AppViewModel())
} 
