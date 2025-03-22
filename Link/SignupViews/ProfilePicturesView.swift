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
    @State private var draggedItem: UIImage?
    @State private var uploadTasks: [StorageUploadTask] = []
    @Binding var isAuthenticated: Bool
    @EnvironmentObject var appViewModel: AppViewModel
    @Namespace private var namespace
    
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
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 133)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color("Gold"), style: StrokeStyle(lineWidth: 2, dash: [5]))
                                )
                                .contentShape(Rectangle())
                                .matchedGeometryEffect(id: image, in: namespace)
                                .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.8), value: selectedImages)
                                .onDrag {
                                    hapticFeedback()
                                    draggedItem = image
                                    return NSItemProvider(object: UIImage())
                                }
                                .onDrop(of: [.item], delegate: DropViewDelegate(item: image, items: $selectedImages, draggedItem: $draggedItem))
                        }
                        
                        // Add button placeholders
                        ForEach(selectedImages.count..<requiredPhotoCount, id: \.self) { _ in
                            Button(action: {
                                withAnimation {
                                    showPhotoPicker = true
                                }
                            }) {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color("Gold"), style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .frame(width: 100, height: 133)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "plus")
                                                .foregroundColor(Color("Gold"))
                                                .font(.system(size: 30))
                                            Text("Add Photo")
                                                .font(.caption)
                                                .foregroundColor(Color("Gold"))
                                        }
                                    )
                            }
                        }
                    }
                    .padding()
                    
                    VStack(spacing: 8) {
                        Text("Drag to reorder")
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
            .navigationBarBackButtonHidden(true)
            .photosPicker(isPresented: $showPhotoPicker,
                         selection: $selectedItems,
                         maxSelectionCount: requiredPhotoCount - selectedImages.count,
                         matching: .images,
                         preferredItemEncoding: .automatic)
            .tint(Color("Gold"))
            .onChange(of: selectedItems) { _ , newItems in
                Task {
                    showPhotoPicker = false
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            selectedImages.append(image)
                        }
                    }
                    selectedItems.removeAll()
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
        
        // Delete existing local images
        ImageStorageManager.shared.deleteAllImages(for: userId)
        
        for (index, image) in selectedImages.enumerated() {
            group.enter()
            
            // Save image locally
            do {
                try ImageStorageManager.shared.saveImage(image, for: userId, at: index)
            } catch {
                print("Error saving image locally: \(error.localizedDescription)")
            }
            
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
                // Save URLs locally
                ImageStorageManager.shared.saveImageUrls(uploadedUrls, for: userId)
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
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

struct DropViewDelegate: DropDelegate {
    let item: UIImage
    @Binding var items: [UIImage]
    @Binding var draggedItem: UIImage?
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedItem = draggedItem else { return false }
        
        if let fromIndex = items.firstIndex(where: { $0 === draggedItem }),
           let toIndex = items.firstIndex(where: { $0 === item }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                let from = items[fromIndex]
                items[fromIndex] = items[toIndex]
                items[toIndex] = from
            }
        }
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedItem = draggedItem else { return }
        
        if let fromIndex = items.firstIndex(where: { $0 === draggedItem }),
           let toIndex = items.firstIndex(where: { $0 === item }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                let from = items[fromIndex]
                items[fromIndex] = items[toIndex]
                items[toIndex] = from
            }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}

#Preview {
    ProfilePicturesView(isAuthenticated: .constant(false))
        .environmentObject(AppViewModel())
} 
