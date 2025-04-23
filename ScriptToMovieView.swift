import SwiftUI
import AVKit

struct ScriptToMovieView: View {
    @StateObject private var viewModel = ScriptToMovieViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var script = ""
    @State private var styleSelection = "Animated"
    
    let styles = ["Animated", "Realistic", "Cartoon", "Sketch", "3D"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("AI Script to Movie")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Enter a script and convert it into a short movie")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading) {
                        Text("Script")
                            .font(.headline)
                        
                        TextEditor(text: $script)
                            .frame(minHeight: 200)
                            .padding(4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Text("\(script.count) characters")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading) {
                        Text("Visual Style")
                            .font(.headline)
                        
                        Picker("Style", selection: $styleSelection) {
                            ForEach(styles, id: \.self) { style in
                                Text(style).tag(style)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        viewModel.generateMovie(from: script, style: styleSelection)
                    }) {
                        HStack {
                            if viewModel.isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 5)
                            } else {
                                Image(systemName: "film")
                            }
                            Text(viewModel.isGenerating ? "Generating..." : "Create Movie")
                        }
                        .frame(minWidth: 200)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(script.count < 50 || viewModel.isGenerating)
                    
                    if viewModel.isGenerating {
                        VStack {
                            ProgressView(value: viewModel.generationProgress)
                                .padding(.horizontal)
                            
                            Text("\(Int(viewModel.generationProgress * 100))% - \(viewModel.generationStatusMessage)")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 5)
                        }
                    }
                    
                    if let videoURL = viewModel.generatedVideoURL {
                        VStack {
                            Text("Your movie is ready!")
                                .font(.headline)
                                .foregroundColor(.green)
                            
                            VideoPlayer(player: AVPlayer(url: videoURL))
                                .frame(height: 200)
                                .cornerRadius(8)
                                .padding(.horizontal)
                            
                            HStack {
                                Button(action: {
                                    viewModel.saveVideoToPhotos()
                                }) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.down")
                                        Text("Save")
                                    }
                                    .frame(minWidth: 100)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                
                                Button(action: {
                                    viewModel.shareVideo()
                                }) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Share")
                                    }
                                    .frame(minWidth: 100)
                                    .padding()
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
                    
                    if !viewModel.errorMessage.isEmpty {
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

class ScriptToMovieViewModel: ObservableObject {
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0
    @Published var generationStatusMessage = "Initializing"
    @Published var generatedVideoURL: URL?
    @Published var errorMessage = ""
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    private let scriptToMovieService = ScriptToMovieService()
    
    func generateMovie(from script: String, style: String) {
        guard !script.isEmpty else {
            errorMessage = "Please enter a script"
            return
        }
        
        isGenerating = true
        generationProgress = 0
        errorMessage = ""
        generatedVideoURL = nil
        
        scriptToMovieService.generateMovie(from: script, style: style) { [weak self] progress, status in
            DispatchQueue.main.async {
                self?.generationProgress = progress
                self?.generationStatusMessage = status
            }
        } completion: { [weak self] result in
            DispatchQueue.main.async {
                self?.isGenerating = false
                
                switch result {
                case .success(let videoURL):
                    self?.generatedVideoURL = videoURL
                case .failure(let error):
                    self?.errorMessage = "Generation failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func saveVideoToPhotos() {
        guard let url = generatedVideoURL else {
            showAlert(title: "Error", message: "No video to save")
            return
        }
        
        scriptToMovieService.saveVideoToPhotos(url: url) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert(title: "Save Error", message: error.localizedDescription)
                } else {
                    self?.showAlert(title: "Success", message: "Video saved to your photo library")
                }
            }
        }
    }
    
    func shareVideo() {
        guard let url = generatedVideoURL else {
            showAlert(title: "Error", message: "No video to share")
            return
        }
        
        scriptToMovieService.shareVideo(url: url)
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

struct ScriptToMovieView_Previews: PreviewProvider {
    static var previews: some View {
        ScriptToMovieView()
    }
}
