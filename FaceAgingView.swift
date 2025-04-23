import SwiftUI

struct FaceAgingView: View {
    @StateObject private var viewModel = FaceAgingViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showingImagePicker = false
    @State private var sliderValue: Double = 20
    @State private var processingImage = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("AI Face Aging")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Upload a portrait photo and see how you might look as you age")
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
                            Text("Age Adjustment: \(Int(sliderValue)) years")
                                .font(.headline)
                            
                            Slider(value: $sliderValue, in: 5...70, step: 5)
                                .padding(.vertical)
                            
                            Button(action: {
                                processingImage = true
                                viewModel.processImage(targetAge: Int(sliderValue)) { success in
                                    processingImage = false
                                }
                            }) {
                                HStack {
                                    if processingImage {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .padding(.trailing, 5)
                                    } else {
                                        Image(systemName: "wand.and.stars")
                                    }
                                    Text(processingImage ? "Processing..." : "Generate Aged Photo")
                                }
                                .frame(minWidth: 200)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(processingImage)
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
                            
                            Button(action: {
                                viewModel.saveResultImage()
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

class FaceAgingViewModel: ObservableObject {
    @Published var inputImage: UIImage?
    @Published var resultImage: UIImage?
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    private let faceAgingService = FaceAgingService()
    
    func processImage(targetAge: Int, completion: @escaping (Bool) -> Void) {
        guard let image = inputImage else {
            showAlert(title: "Error", message: "No image selected")
            completion(false)
            return
        }
        
        faceAgingService.ageFace(image: image, targetAge: targetAge) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let processedImage):
                    self?.resultImage = processedImage
                    completion(true)
                case .failure(let error):
                    self?.showAlert(title: "Processing Error", message: error.localizedDescription)
                    completion(false)
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
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

struct FaceAgingView_Previews: PreviewProvider {
    static var previews: some View {
        FaceAgingView()
    }
}
