import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

struct ProfileHeaderView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(Color("Gold"))
                .padding(.bottom, 8)
            
            Text("Edit Profile")
                .font(.custom("Lora-Regular", size: 19))
                .foregroundColor(Color.accent)
        }
        .padding(.top, 40)
    }
}

struct PhotoGridView: View {
    @Binding var selectedImages: [UIImage]
    @Binding var showPhotoPicker: Bool
    @Binding var selectedItems: [PhotosPickerItem]
    @Binding var draggedItem: UIImage?
    let namespace: Namespace.ID
    let requiredPhotoCount: Int
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                PhotoCell(
                    image: image,
                    index: index,
                    selectedImages: $selectedImages,
                    draggedItem: $draggedItem,
                    namespace: namespace
                )
            }
            
            ForEach(selectedImages.count..<requiredPhotoCount, id: \.self) { _ in
                AddPhotoButton(showPhotoPicker: $showPhotoPicker)
            }
        }
        .padding()
    }
}

struct PhotoCell: View {
    let image: UIImage
    let index: Int
    @Binding var selectedImages: [UIImage]
    @Binding var draggedItem: UIImage?
    let namespace: Namespace.ID
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
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
            
            DeleteButton(selectedImages: $selectedImages, index: index)
        }
    }
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

struct DeleteButton: View {
    @Binding var selectedImages: [UIImage]
    let index: Int
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedImages = selectedImages.enumerated()
                    .filter { $0.offset != index }
                    .map { $0.element }
            }
        }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.white)
                .background(Color.black.opacity(0.5))
                .clipShape(Circle())
                .padding(4)
        }
        .offset(x: 4, y: -4)
    }
}

struct AddPhotoButton: View {
    @Binding var showPhotoPicker: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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

struct PhotosSection: View {
    @Binding var selectedImages: [UIImage]
    @Binding var showPhotoPicker: Bool
    @Binding var selectedItems: [PhotosPickerItem]
    @Binding var draggedItem: UIImage?
    let namespace: Namespace.ID
    let requiredPhotoCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Profile Photos")
                .font(.headline)
                .foregroundColor(Color.accent)
                .padding(.horizontal)
            
            PhotoGridView(
                selectedImages: $selectedImages,
                showPhotoPicker: $showPhotoPicker,
                selectedItems: $selectedItems,
                draggedItem: $draggedItem,
                namespace: namespace,
                requiredPhotoCount: requiredPhotoCount
            )
            
            VStack(spacing: 8) {
                Text("Drag to reorder")
                    .font(.custom("Lora-Regular", size: 15))
                    .foregroundColor(Color.accent)
                Text("\(requiredPhotoCount) required")
                    .font(.custom("Lora-Regular", size: 15))
                    .foregroundColor(Color.accent)
            }
        }
    }
}

struct SaveButton: View {
    let isLoading: Bool
    let selectedImagesCount: Int
    let requiredPhotoCount: Int
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.2)
            } else if selectedImagesCount == requiredPhotoCount {
                Button(action: action) {
                    HStack {
                        Text("Save Changes")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "checkmark")
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
}

struct EditProfileView: View {
    @Binding var userName: String
    @Binding var isAuthenticated: Bool
    @Binding var selectedTab: String
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showPhotoPicker = false
    @State private var draggedItem: UIImage?
    @State private var uploadTasks: [StorageUploadTask] = []
    @State private var existingPhotoUrls: [String] = []
    @Environment(\.dismiss) private var dismiss
    @Namespace private var namespace
    
    private let requiredPhotoCount = 6
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    ProfileHeaderView()
                    
                    PhotosSection(
                        selectedImages: $selectedImages,
                        showPhotoPicker: $showPhotoPicker,
                        selectedItems: $selectedItems,
                        draggedItem: $draggedItem,
                        namespace: namespace,
                        requiredPhotoCount: requiredPhotoCount
                    )
                    
                    Spacer()
                    
                    SaveButton(
                        isLoading: isLoading,
                        selectedImagesCount: selectedImages.count,
                        requiredPhotoCount: requiredPhotoCount,
                        action: uploadPhotos
                    )
                }
                .padding()
            }
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
                for task in uploadTasks {
                    task.cancel()
                }
                uploadTasks.removeAll()
            }
            .onAppear {
                loadExistingPhotos()
            }
        }
    }
    
    private func loadExistingPhotos() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // First try to load from local storage
        if let localUrls = ImageStorageManager.shared.loadImageUrls(for: userId) {
            existingPhotoUrls = localUrls
            for index in 0..<localUrls.count {
                if let image = ImageStorageManager.shared.loadImage(for: userId, at: index) {
                    selectedImages.append(image)
                }
            }
            return
        }
        
        // If not found locally, load from Firestore
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                errorMessage = "Error loading photos: \(error.localizedDescription)"
                showError = true
                return
            }
            
            if let document = document,
               let photoUrls = document.data()?["profilePictures"] as? [String] {
                existingPhotoUrls = photoUrls
                // Save URLs locally
                ImageStorageManager.shared.saveImageUrls(photoUrls, for: userId)
                
                for (index, urlString) in photoUrls.enumerated() {
                    if let url = URL(string: urlString) {
                        URLSession.shared.dataTask(with: url) { data, _, _ in
                            if let data = data, let image = UIImage(data: data) {
                                DispatchQueue.main.async {
                                    selectedImages.append(image)
                                    // Save image locally
                                    try? ImageStorageManager.shared.saveImage(image, for: userId, at: index)
                                }
                            }
                        }.resume()
                    }
                }
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
        
        for task in uploadTasks {
            task.cancel()
        }
        uploadTasks.removeAll()
        
        // Delete existing local images
        ImageStorageManager.shared.deleteAllImages(for: userId)
        
        for urlString in existingPhotoUrls {
            if let url = URL(string: urlString) {
                let storageRef = storage.reference(forURL: urlString)
                storageRef.delete { error in
                    if let error = error {
                        print("Error deleting photo: \(error.localizedDescription)")
                    }
                }
            }
        }
        
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
        selectedTab = "Profile"
    }
    
    private func savePhotoUrlsToFirestore(urls: [String], userId: String) {
        db.collection("users").document(userId).updateData([
            "profilePictures": urls
        ]) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Failed to save photo URLs: \(error.localizedDescription)"
                showError = true
            } else {
                selectedTab = "Profile"
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileView(userName: .constant("Preview User"), isAuthenticated: .constant(true), selectedTab: .constant("Profile"))
    }
} 
