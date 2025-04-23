import SwiftUI

struct ContentView: View {
    @State private var selectedFeature: Feature? = nil
    
    enum Feature: String, CaseIterable, Identifiable {
        case faceAging = "AI Face Aging"
        case youtubeDownload = "YouTube Video Download"
        case webSearch = "Web Search"
        case scriptToMovie = "AI Script to Movie"
        case hairRemoval = "AI Hair Removal"
        
        var id: String { self.rawValue }
        
        var iconName: String {
            switch self {
            case .faceAging: return "person.crop.rectangle"
            case .youtubeDownload: return "arrow.down.circle"
            case .webSearch: return "magnifyingglass"
            case .scriptToMovie: return "film"
            case .hairRemoval: return "scissors"
            }
        }
        
        var description: String {
            switch self {
            case .faceAging: return "See how you might look when you're older using AI"
            case .youtubeDownload: return "Download videos from YouTube"
            case .webSearch: return "Search the web with AI assistance"
            case .scriptToMovie: return "Convert text scripts into animated movies"
            case .hairRemoval: return "Remove unwanted hair from photos using AI"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("AI Multi-Tool")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                Text("Select a feature to use:")
                    .font(.headline)
                    .padding(.bottom)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(Feature.allCases) { feature in
                        FeatureButton(feature: feature) {
                            selectedFeature = feature
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .sheet(item: $selectedFeature) { feature in
                getFeatureView(for: feature)
            }
            .navigationBarTitle("AI Multi-Tool", displayMode: .inline)
        }
    }
    
    @ViewBuilder
    private func getFeatureView(for feature: Feature) -> some View {
        switch feature {
        case .faceAging:
            FaceAgingView()
        case .youtubeDownload:
            YouTubeDownloadView()
        case .webSearch:
            WebSearchView()
        case .scriptToMovie:
            ScriptToMovieView()
        case .hairRemoval:
            HairRemovalView()
        }
    }
}

struct FeatureButton: View {
    let feature: ContentView.Feature
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: feature.iconName)
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
                    .frame(height: 60)
                
                Text(feature.rawValue)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 160)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
