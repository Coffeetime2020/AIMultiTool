import Foundation
import UIKit

// This file contains shared model definitions used across the app

// Generic result type for API responses
enum APIResult<T, E: Error> {
    case success(T)
    case failure(E)
}

// Generic progress update for tracking long-running operations
struct ProgressUpdate {
    let progress: Double // 0.0 to 1.0
    let message: String
}

// App settings model
struct AppSettings {
    var useDarkMode: Bool = false
    var saveOriginalImages: Bool = true
    var highQualityProcessing: Bool = true
    var autoSaveResults: Bool = false
}

// User model for potential future authentication features
struct User {
    let id: String
    let username: String
    var profileImage: UIImage?
    var preferredSettings: AppSettings
    
    // Usage tracking for potential premium features
    var usageStats: UsageStats
    
    init(id: String, username: String) {
        self.id = id
        self.username = username
        self.profileImage = nil
        self.preferredSettings = AppSettings()
        self.usageStats = UsageStats()
    }
}

// Usage statistics for tracking API usage
struct UsageStats {
    var faceAgingUsageCount: Int = 0
    var youtubeDownloadCount: Int = 0
    var webSearchCount: Int = 0
    var scriptToMovieCount: Int = 0
    var hairRemovalCount: Int = 0
    
    var totalUsage: Int {
        return faceAgingUsageCount + youtubeDownloadCount + webSearchCount + 
               scriptToMovieCount + hairRemovalCount
    }
    
    mutating func incrementUsage(for feature: FeatureType) {
        switch feature {
        case .faceAging:
            faceAgingUsageCount += 1
        case .youtubeDownload:
            youtubeDownloadCount += 1
        case .webSearch:
            webSearchCount += 1
        case .scriptToMovie:
            scriptToMovieCount += 1
        case .hairRemoval:
            hairRemovalCount += 1
        }
    }
}

// Feature type enum
enum FeatureType {
    case faceAging
    case youtubeDownload
    case webSearch
    case scriptToMovie
    case hairRemoval
}

// Processing quality options
enum ProcessingQuality: String, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .low:
            return "Faster processing, lower quality"
        case .medium:
            return "Balanced speed and quality"
        case .high:
            return "Best quality, slower processing"
        }
    }
}
