import Foundation

// This file manages API keys for the various services
// In a real implementation, these would be securely stored and retrieved
struct APIKeys {
    // Retrieve API keys from environment variables or use fallback demo keys
    static let faceAgingAPI = ProcessInfo.processInfo.environment["FACE_AGING_API_KEY"] ?? "demo_face_aging_key"
    static let youtubeAPI = ProcessInfo.processInfo.environment["YOUTUBE_API_KEY"] ?? "demo_youtube_key"
    static let webSearchAPI = ProcessInfo.processInfo.environment["WEB_SEARCH_API_KEY"] ?? "demo_search_key"
    static let scriptToMovieAPI = ProcessInfo.processInfo.environment["SCRIPT_TO_MOVIE_API_KEY"] ?? "demo_script_movie_key"
    static let hairRemovalAPI = ProcessInfo.processInfo.environment["HAIR_REMOVAL_API_KEY"] ?? "demo_hair_removal_key"
}
