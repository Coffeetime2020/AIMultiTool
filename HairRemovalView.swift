import SwiftUI

struct HairRemovalView: View {
    @StateObject private var viewModel = HairRemovalViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showingImagePicker = false
    @State private var intensity: Double = 0.5
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("AI Hair Removal")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Upload a photo to remove unwanted hair using AI")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    if viewModel.inputImage != nil {
                        Image(uiImage: viewModel.inputImage!)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(10)
                            .padding()
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                            
                            VStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                Text("No Image Selected")
                                    .font(.headline)
                            }
                            .foregroundColor(.gray)
                        }
                        .padding()
                    }
                    
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text(viewModel.inputImage == nil ? "Select Photo" : "Change Photo")
                        }
                        .frame(minWidth: 200)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    if viewModel.inputImage != nil {
                        VStack(alignment: .leading) {
                            Text("Removal Intensity: \(Int(intensity * 100))%")
                                .font(.headline)
                            
                            Slider(value: $intensity, in: 0.1...1.0, step: 0.1)
                                .padding(.vertical)
                            
                            Button(action: {
                                viewModel.processImage(intensity: intensity)
                            }) {
                                HStack {
                                    if viewModel.isProcessing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .padding(.trailing, 5)
                                    } else {
                                        Image(systemName: "wand.and.stars")
                                    }
                                    Text(viewModel.isProcessing ? "Processing..." : "Remove Hair")
                                }
                                .frame(minWidth: 200)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(viewModel.isProcessing)
                        }
                        .padding()
                    }
                    
                    if viewModel.resultImage != nil {
                        VStack {
                            Text("Result")
                                .font(.headline)
                            
                            Image(uiImage: viewModel.resultImage!)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(10)
                                .padding()
                            
                            HStack {
                                Button(action: {
                                    viewModel.saveResultImage()
                                }) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.down")
                                        Text("Save")
                                    }
                                    .frame(minWidth: 100)
                                    .padding()
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                
                                Button(action: {
                                    viewModel.shareImage()
                                }) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Share")
                                    }
                                    .frame(minWidth: 100)
                                    .padding()
                                    .background(Color.purple)
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
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $viewModel.inputImage)
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

class HairRemovalViewModel: ObservableObject {
    @Published var inputImage: UIImage?
    @Published var resultImage: UIImage?
    @Published var isProcessing = false
    @Published var errorMessage = ""
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    private let hairRemovalService = HairRemovalService()
    
    func processImage(intensity: Double) {
        guard let image = inputImage else {
            errorMessage = "No image selected"
            return
        }
        
        isProcessing = true
        errorMessage = ""
        
        hairRemovalService.removeHair(from: image, intensity: intensity) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                
                switch result {
                case .success(let processedImage):
                    self?.resultImage = processedImage
                case .failure(let error):
                    self?.errorMessage = "Processing failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func saveResultImage() {
        guard let image = resultImage else {
            showAlert(title: "Error", message: "No result image to save")
            return
        }
        
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
    }
    
    @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            showAlert(title: "Save Error", message: error.localizedDescription)
        } else {
            showAlert(title: "Saved", message: "Image has been saved to your photos")
        }
    }
    
    func shareImage() {
        guard let image = resultImage else {
            showAlert(title: "Error", message: "No result image to share")
            return
        }
        
        hairRemovalService.shareImage(image)
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

struct HairRemovalView_Previews: PreviewProvider {
    static var previews: some View {
        HairRemovalView()
    }
}
