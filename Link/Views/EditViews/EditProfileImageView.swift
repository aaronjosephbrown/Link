import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

struct EditProfileImageView: View {
    @Binding var userName: String
    @Binding var isAuthenticated: Bool
    @Binding var selectedTab: String
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var showActionSheet = false
    @State private var currentImageIndex = 0
    var isProfileSetup: Bool = false
    var onProfileImagesUpdated: (() -> Void)?
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var draggedItem: UIImage?
    @State private var uploadTasks: [StorageUploadTask] = []
    @State private var existingPhotoUrls: [String] = []
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
                                        showImagePicker = true
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
                    
                    // Save/Next button
                    VStack(spacing: 16) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(1.2)
                        } else if selectedImages.count == requiredPhotoCount {
                            Button(action: {
                                saveAndContinue()
                            }) {
                                HStack {
                                    Text(isProfileSetup ? "Next" : "Save Changes")
                                        .font(.system(size: 17, weight: .semibold))
                                    Image(systemName: isProfileSetup ? "arrow.right" : "checkmark")
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
            .photosPicker(isPresented: $showImagePicker,
                         selection: $selectedItems,
                         maxSelectionCount: requiredPhotoCount - selectedImages.count,
                         matching: .images,
                         preferredItemEncoding: .automatic)
            .tint(Color("Gold"))
            .onChange(of: selectedItems) { _ , newItems in
                Task {
                    showImagePicker = false
                    for item in newItems {
                        do {
                            if let data = try await item.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                selectedImages.append(image)
                            }
                        } catch {
                            print("Error loading image: \(error.localizedDescription)")
                            errorMessage = "Error loading image: \(error.localizedDescription)"
                            showError = true
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
                
                for url in photoUrls {
                    group.enter()
                    storage.reference(forURL: url).downloadURL { url, error in
                        defer { group.leave() }
                        
                        if let error = error {
                            print("Error downloading image: \(error.localizedDescription)")
                            return
                        }
                        
                        guard let url = url else { return }
                        
                        URLSession.shared.dataTask(with: url) { data, response, error in
                            if let error = error {
                                print("Error loading image data: \(error.localizedDescription)")
                                return
                            }
                            
                            guard let data = data,
                                  let image = UIImage(data: data) else { return }
                            
                            DispatchQueue.main.async {
                                loadedImages.append(image)
                                if loadedImages.count == photoUrls.count {
                                    selectedImages = loadedImages
                                }
                            }
                        }.resume()
                    }
                }
            }
        }
    }
    
    private func saveAndContinue() {
        guard !selectedImages.isEmpty else {
            errorMessage = "Please select at least one image"
            showError = true
            return
        }
        
        guard !isLoading else { return }
        isLoading = true
        
        Task {
            do {
                try await saveImages()
                DispatchQueue.main.async {
                    self.isLoading = false
                    if self.isProfileSetup {
                        self.profileViewModel.shouldAdvanceToNextStep = true
                        self.appViewModel.updateProgress(.photosComplete)
                    } else {
                        self.onProfileImagesUpdated?()
                        self.dismiss()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
    
    private func saveImages() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user found"
            showError = true
            return
        }
        
        // Delete existing photos from storage
        for url in existingPhotoUrls {
            storage.reference(forURL: url).delete { error in
                if let error = error {
                    print("Error deleting old photo: \(error.localizedDescription)")
                }
            }
        }
        
        // Upload new photos
        var newPhotoUrls: [String] = []
        let group = DispatchGroup()
        
        for (index, image) in selectedImages.enumerated() {
            group.enter()
            
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                group.leave()
                continue
            }
            
            let photoRef = storage.reference().child("users/\(userId)/photos/\(index).jpg")
            let uploadTask = photoRef.putData(imageData, metadata: nil) { metadata, error in
                defer { group.leave() }
                
                if let error = error {
                    errorMessage = "Error uploading photo: \(error.localizedDescription)"
                    showError = true
                    return
                }
                
                photoRef.downloadURL { url, error in
                    if let error = error {
                        errorMessage = "Error getting download URL: \(error.localizedDescription)"
                        showError = true
                        return
                    }
                    
                    if let url = url {
                        newPhotoUrls.append(url.absoluteString)
                    }
                }
            }
            
            uploadTasks.append(uploadTask)
        }
        
        group.notify(queue: .main) {
            if newPhotoUrls.count == requiredPhotoCount {
                // Save URLs to Firestore
                db.collection("users").document(userId).updateData([
                    "profilePictures": newPhotoUrls
                ]) { error in
                    isLoading = false
                    
                    if let error = error {
                        errorMessage = "Error saving photo URLs: \(error.localizedDescription)"
                        showError = true
                        return
                    }
                    
                    // Save URLs locally
                    ImageStorageManager.shared.saveImageUrls(newPhotoUrls, for: userId)
                    
                    // Save images locally
                    for (index, image) in selectedImages.enumerated() {
                        do {
                            try ImageStorageManager.shared.saveImage(image, for: userId, at: index)
                        } catch {
                            print("Error saving image locally: \(error.localizedDescription)")
                            errorMessage = "Error saving image locally: \(error.localizedDescription)"
                            showError = true
                            return
                        }
                    }
                    
                    onProfileImagesUpdated?()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileImageView(userName: .constant("Preview User"), isAuthenticated: .constant(true), selectedTab: .constant("Profile"))
    }
} 

