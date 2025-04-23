import UIKit
import AVFoundation

class YouTubeService {
    enum YouTubeServiceError: Error {
        case invalidURL
        case downloadFailed
        case fileWriteFailed
        case networkError
        case invalidResponse
        case noVideoInfo
        
        var localizedDescription: String {
            switch self {
            case .invalidURL:
                return "The YouTube URL is invalid."
            case .downloadFailed:
                return "Failed to download the video."
            case .fileWriteFailed:
                return "Failed to save the video file."
            case .networkError:
                return "Network connection error. Please check your internet connection."
            case .invalidResponse:
                return "Received an invalid response from the server."
            case .noVideoInfo:
                return "Could not retrieve video information."
            }
        }
    }
    
    struct VideoInfo {
        let title: String
        let thumbnail: UIImage
        let duration: String
    }
    
    // In a real implementation, this would use an actual API key from environment variables
    private let apiKey = ProcessInfo.processInfo.environment["YOUTUBE_API_KEY"] ?? "demo_key"
    
    func getVideoInfo(from url: String, completion: @escaping (Result<VideoInfo, YouTubeServiceError>) -> Void) {
        // Validate the URL
        guard let _ = URL(string: url), url.contains("youtube.com") || url.contains("youtu.be") else {
            completion(.failure(.invalidURL))
            return
        }
        
        // For demo purposes, we'll simulate the API call and return a dummy video info
        // In a real implementation, this would make an actual API request to YouTube's API
        simulateVideoInfoAPICall(url: url, completion: completion)
    }
    
    func downloadVideo(from url: String, quality: String, progressHandler: @escaping (Double) -> Void, completion: @escaping (Result<URL, YouTubeServiceError>) -> Void) {
        // Validate the URL
        guard let _ = URL(string: url), url.contains("youtube.com") || url.contains("youtu.be") else {
            completion(.failure(.invalidURL))
            return
        }
        
        // For demo purposes, we'll simulate downloading a video and return a local video file
        // In a real implementation, this would make an actual download request
        simulateVideoDownload(url: url, quality: quality, progressHandler: progressHandler, completion: completion)
    }
    
    func saveVideoToPhotos(url: URL, completion: @escaping (Error?) -> Void) {
        // In a real implementation, this would use PHPhotoLibrary to save the video
        // For demo purposes, we'll simulate saving the video
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            completion(nil) // Simulate successful save
        }
    }
    
    // MARK: - Private Simulation Methods
    
    private func simulateVideoInfoAPICall(url: String, completion: @escaping (Result<VideoInfo, YouTubeServiceError>) -> Void) {
        // Simulate network delay
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
            // Extract video ID from URL for demonstration purposes
            let videoID = self.extractVideoID(from: url) ?? "dQw4w9WgXcQ" // Default to a known video ID if extraction fails
            
            // Create a dummy image for thumbnail
            let thumbnailImage = self.createDummyThumbnail(videoID: videoID)
            
            // Create video info
            let videoInfo = VideoInfo(
                title: "Sample YouTube Video - \(videoID)",
                thumbnail: thumbnailImage,
                duration: "4:20"
            )
            
            completion(.success(videoInfo))
        }
    }
    
    private func simulateVideoDownload(url: String, quality: String, progressHandler: @escaping (Double) -> Void, completion: @escaping (Result<URL, YouTubeServiceError>) -> Void) {
        // Simulate download progress updates
        var progress: Double = 0.0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            progress += 0.05
            progressHandler(min(progress, 0.95))
            
            if progress >= 1.0 {
                timer.invalidate()
            }
        }
        
        // Simulate download completion after delay
        DispatchQueue.global().asyncAfter(deadline: .now() + 4.0) {
            timer.invalidate()
            progressHandler(1.0)
            
            // In a real implementation, we would save the downloaded video to a temporary file
            // For demo purposes, we'll just create a dummy video file URL
            if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let videoFilename = "youtube_video_\(Int(Date().timeIntervalSince1970)).mp4"
                let videoFileURL = documentsDirectory.appendingPathComponent(videoFilename)
                
                // Simulate file creation (in a real app, we would write actual video data)
                // Here, we're just pretending the file exists
                completion(.success(videoFileURL))
            } else {
                completion(.failure(.fileWriteFailed))
            }
        }
    }
    
    // Helper function to extract YouTube video ID from URL
    private func extractVideoID(from url: String) -> String? {
        if url.contains("youtube.com/watch") {
            // Extract from standard YouTube URL
            if let queryItems = URLComponents(string: url)?.queryItems {
                return queryItems.first(where: { $0.name == "v" })?.value
            }
        } else if url.contains("youtu.be/") {
            // Extract from shortened YouTube URL
            if let range = url.range(of: "youtu.be/") {
                let startIndex = range.upperBound
                if let endIndex = url[startIndex...].firstIndex(where: { $0 == "?" || $0 == "&" || $0 == "#" }) {
                    return String(url[startIndex..<endIndex])
                } else {
                    return String(url[startIndex...])
                }
            }
        }
        return nil
    }
    
    // Create a dummy thumbnail image with the video ID
    private func createDummyThumbnail(videoID: String) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 320, height: 180))
        
        return renderer.image { ctx in
            // Draw background
            UIColor.darkGray.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 320, height: 180))
            
            // Draw play button
            let playButtonRect = CGRect(x: 135, y: 65, width: 50, height: 50)
            UIColor.white.setFill()
            UIBezierPath(ovalIn: playButtonRect).fill()
            
            UIColor.red.setFill()
            let trianglePath = UIBezierPath()
            trianglePath.move(to: CGPoint(x: 150, y: 75))
            trianglePath.addLine(to: CGPoint(x: 175, y: 90))
            trianglePath.addLine(to: CGPoint(x: 150, y: 105))
            trianglePath.close()
            trianglePath.fill()
            
            // Draw video ID as text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.white
            ]
            
            let displayID = "Video ID: \(videoID.prefix(10))..."
            let textRect = CGRect(x: 10, y: 150, width: 300, height: 20)
            displayID.draw(in: textRect, withAttributes: attributes)
        }
    }
}
