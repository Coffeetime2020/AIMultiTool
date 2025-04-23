import SwiftUI
import AVKit

struct YouTubeDownloadView: View {
    @StateObject private var viewModel = YouTubeDownloadViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var videoURL = ""
    @State private var selectedQuality = "720p"
    
    let availableQualities = ["360p", "480p", "720p", "1080p"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("YouTube Video Downloader")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Enter a YouTube video URL to download")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    TextField("YouTube URL", text: $videoURL)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                        )
                        .padding(.horizontal)
                    
                    HStack {
                        Text("Quality:")
                            .font(.headline)
                        
                        Picker("Quality", selection: $selectedQuality) {
                            ForEach(availableQualities, id: \.self) { quality in
                                Text(quality).tag(quality)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.horizontal)
                    
                    if viewModel.thumbnailImage != nil {
                        VStack {
                            Text("Video Preview")
                                .font(.headline)
                            
                            Image(uiImage: viewModel.thumbnailImage!)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 180)
                                .cornerRadius(8)
                            
                            if !viewModel.videoTitle.isEmpty {
                                Text(viewModel.videoTitle)
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            
                            if !viewModel.videoDuration.isEmpty {
                                Text("Duration: \(viewModel.videoDuration)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                    }
                    
                    Button(action: {
                        if viewModel.state == .idle || viewModel.state == .error {
                            viewModel.getVideoInfo(from: videoURL)
                        }
                    }) {
                        HStack {
                            if viewModel.state == .loading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 5)
                            } else {
                                Image(systemName: "info.circle")
                            }
                            Text(viewModel.state == .loading ? "Loading..." : "Get Video Info")
                        }
                        .frame(minWidth: 200)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(videoURL.isEmpty || viewModel.state == .loading)
                    
                    if viewModel.state == .ready {
                        Button(action: {
                            viewModel.downloadVideo(from: videoURL, quality: selectedQuality)
                        }) {
                            HStack {
                                if viewModel.state == .downloading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .padding(.trailing, 5)
                                } else {
                                    Image(systemName: "arrow.down.circle")
                                }
                                Text(viewModel.state == .downloading ? "Downloading..." : "Download Video")
                            }
                            .frame(minWidth: 200)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(viewModel.state == .downloading)
                    }
                    
                    if viewModel.downloadProgress > 0 && viewModel.downloadProgress < 1.0 {
                        VStack {
                            ProgressView(value: viewModel.downloadProgress)
                                .padding(.horizontal)
                            
                            Text("\(Int(viewModel.downloadProgress * 100))%")
                                .font(.caption)
                                .padding(.top, 5)
                        }
                    }
                    
                    if let downloadedURL = viewModel.downloadedFileURL {
                        VStack {
                            Text("Download Complete!")
                                .font(.headline)
                                .foregroundColor(.green)
                            
                            if downloadedURL.pathExtension.lowercased() == "mp4" {
                                VideoPlayer(player: AVPlayer(url: downloadedURL))
                                    .frame(height: 200)
                                    .cornerRadius(8)
                                    .padding()
                            }
                            
                            Button(action: {
                                viewModel.saveVideoToPhotos()
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Save to Photos")
                                }
                                .frame(minWidth: 200)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                    }
                    
                    if viewModel.state == .error {
                        Text(viewModel.errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .alert(isPresented: $viewModel.showingAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
            })
        }
    }
}

class YouTubeDownloadViewModel: ObservableObject {
    enum DownloadState {
        case idle, loading, ready, downloading, complete, error
    }
    
    @Published var state: DownloadState = .idle
    @Published var thumbnailImage: UIImage?
    @Published var videoTitle: String = ""
    @Published var videoDuration: String = ""
    @Published var downloadProgress: Double = 0
    @Published var downloadedFileURL: URL?
    @Published var errorMessage: String = ""
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    private let youtubeService = YouTubeService()
    
    func getVideoInfo(from url: String) {
        guard !url.isEmpty else { return }
        
        state = .loading
        youtubeService.getVideoInfo(from: url) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let videoInfo):
                    self?.thumbnailImage = videoInfo.thumbnail
                    self?.videoTitle = videoInfo.title
                    self?.videoDuration = videoInfo.duration
                    self?.state = .ready
                case .failure(let error):
                    self?.state = .error
                    self?.errorMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func downloadVideo(from url: String, quality: String) {
        guard state == .ready else { return }
        
        state = .downloading
        downloadProgress = 0
        
        youtubeService.downloadVideo(from: url, quality: quality) { [weak self] progress in
            DispatchQueue.main.async {
                self?.downloadProgress = progress
            }
        } completion: { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fileURL):
                    self?.downloadedFileURL = fileURL
                    self?.state = .complete
                case .failure(let error):
                    self?.state = .error
                    self?.errorMessage = "Download failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func saveVideoToPhotos() {
        guard let url = downloadedFileURL else {
            showAlert(title: "Error", message: "No video to save")
            return
        }
        
        youtubeService.saveVideoToPhotos(url: url) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert(title: "Save Error", message: error.localizedDescription)
                } else {
                    self?.showAlert(title: "Success", message: "Video saved to your photo library")
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

struct YouTubeDownloadView_Previews: PreviewProvider {
    static var previews: some View {
        YouTubeDownloadView()
    }
}
