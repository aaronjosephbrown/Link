import Foundation
import UIKit

class ImageStorageManager {
    static let shared = ImageStorageManager()
    private let fileManager = FileManager.default
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func getImageDirectory(for userId: String) -> URL {
        let userDirectory = documentsDirectory.appendingPathComponent("user_images/\(userId)")
        try? fileManager.createDirectory(at: userDirectory, withIntermediateDirectories: true)
        return userDirectory
    }
    
    func saveImage(_ image: UIImage, for userId: String, at index: Int) throws {
        let userDirectory = getImageDirectory(for: userId)
        let imageURL = userDirectory.appendingPathComponent("profile_\(index).jpg")
        
        if let imageData = image.jpegData(compressionQuality: 0.7) {
            try imageData.write(to: imageURL)
        }
    }
    
    func loadImage(for userId: String, at index: Int) -> UIImage? {
        let userDirectory = getImageDirectory(for: userId)
        let imageURL = userDirectory.appendingPathComponent("profile_\(index).jpg")
        
        if let imageData = try? Data(contentsOf: imageURL) {
            return UIImage(data: imageData)
        }
        return nil
    }
    
    func deleteAllImages(for userId: String) {
        let userDirectory = getImageDirectory(for: userId)
        try? fileManager.removeItem(at: userDirectory)
    }
    
    func saveImageUrls(_ urls: [String], for userId: String) {
        let userDirectory = getImageDirectory(for: userId)
        let urlsFile = userDirectory.appendingPathComponent("urls.json")
        
        if let data = try? JSONEncoder().encode(urls) {
            try? data.write(to: urlsFile)
        }
    }
    
    func loadImageUrls(for userId: String) -> [String]? {
        let userDirectory = getImageDirectory(for: userId)
        let urlsFile = userDirectory.appendingPathComponent("urls.json")
        
        if let data = try? Data(contentsOf: urlsFile),
           let urls = try? JSONDecoder().decode([String].self, from: data) {
            return urls
        }
        return nil
    }
} 