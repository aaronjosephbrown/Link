import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

struct EditProfileImageView: View {
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
    
    var onProfileImagesUpdated: (() -> Void)?
    
    var body: some View {
        BackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        HStack {
                            Spacer()
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundColor(Color("Gold"))
                            }
                        }
                        Image(systemName: "photo.stack.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color("Gold"))
                            .padding(.bottom, 8)
                        Text("Edit Profile Photos")
                            .font(.custom("Lora-Regular", size: 19))
                            .foregroundColor(Color.accent)
                    }
                    .padding(.top, 40)
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(Color("Gold"))
                    } else {
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
                                    .overlay(
                                        Button(action: { selectedImages.remove(at: index) }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white)
                                                .background(Color.black.opacity(0.5))
                                                .clipShape(Circle())
                                        }
                                        .padding(4),
                                        alignment: .topTrailing
                                    )
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
                    }
                    
                    Spacer()
                    
                    // Save button
                    VStack(spacing: 16) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(1.2)
                        } else if selectedImages.count == requiredPhotoCount {
                            Button(action: saveChanges) {
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
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    private func loadExistingPhotos() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Clear existing images first
        selectedImages.removeAll()
        existingPhotoUrls.removeAll()
        
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
                
                // Create a dispatch group to handle multiple image loads
                let group = DispatchGroup()
                var loadedImages: [UIImage] = []
                
                for (index, urlString) in photoUrls.enumerated() {
                    group.enter()
                    if let url = URL(string: urlString) {
                        URLSession.shared.dataTask(with: url) { data, _, _ in
                            if let data = data, let image = UIImage(data: data) {
                                loadedImages.append(image)
                                // Save image locally
                                try? ImageStorageManager.shared.saveImage(image, for: userId, at: index)
                            }
                            group.leave()
                        }.resume()
                    } else {
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    // Sort images by their original order
                    selectedImages = loadedImages
                }
            }
        }
    }
    
    private func saveChanges() {
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
            if URL(string: urlString) != nil {
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
                
                // Update all data in Firestore
                let profileData: [String: Any] = [
                    "profilePictures": uploadedUrls,
                    "name": userName,
                    "bio": "",
                    "location": "",
                    "occupation": "",
                    "interests": [],
                    "heightPreference": "",
                    "bodyType": "",
                    "heightImportance": 5,
                    "preferredPartnerHeight": "",
                    "activityLevel": "",
                    "favoriteActivities": [],
                    "preferSimilarFitness": false,
                    "diet": "",
                    "dietaryImportance": 5,
                    "dateDifferentDiet": false,
                    "hasPets": "",
                    "petTypes": [],
                    "dateWithPets": false,
                    "animalPreference": ""
                ]
                
                db.collection("users").document(userId).updateData(profileData) { error in
                    isLoading = false
                    
                    if let error = error {
                        errorMessage = "Failed to save changes: \(error.localizedDescription)"
                        showError = true
                    } else {
                        selectedTab = "Profile"
                        onProfileImagesUpdated?()
                        dismiss()
                    }
                }
            } else {
                errorMessage = "Not all photos were uploaded successfully"
                showError = true
                isLoading = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileImageView(userName: .constant("Preview User"), isAuthenticated: .constant(true), selectedTab: .constant("Profile"))
    }
} 
