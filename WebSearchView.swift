import SwiftUI

struct WebSearchView: View {
    @StateObject private var viewModel = WebSearchViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var searchQuery = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Text("AI-Powered Web Search")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Search the web with AI-enhanced results")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom)
                
                HStack {
                    TextField("Search the web...", text: $searchQuery)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.1))
                        )
                    
                    Button(action: {
                        if !searchQuery.isEmpty {
                            viewModel.performSearch(query: searchQuery)
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(searchQuery.isEmpty || viewModel.isLoading)
                }
                .padding(.horizontal)
                
                if viewModel.isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Searching...")
                            .progressViewStyle(CircularProgressViewStyle())
                        Spacer()
                    }
                } else if !viewModel.searchResults.isEmpty {
                    List {
                        // AI Summary Section
                        if let summary = viewModel.aiSummary, !summary.isEmpty {
                            Section(header: Text("AI Summary")) {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(summary)
                                        .font(.body)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        
                        // Search Results Section
                        Section(header: Text("Web Results")) {
                            ForEach(viewModel.searchResults) { result in
                                SearchResultView(result: result) {
                                    viewModel.openWebPage(url: result.url)
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                } else if viewModel.hasSearched {
                    VStack {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No results found")
                            .font(.headline)
                            .padding()
                        Text("Try a different search term")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    VStack {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Enter a search term above")
                            .font(.headline)
                            .padding()
                        Text("Results will appear here")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                }
            }
            .padding(.top)
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
            })
            .alert(isPresented: $viewModel.showingError) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $viewModel.showingWebView) {
                if let url = viewModel.webViewURL {
                    SafariWebView(url: url)
                }
            }
        }
    }
}

struct SearchResultView: View {
    let result: SearchResult
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(result.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(result.url)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .lineLimit(1)
                
                Text(result.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            .padding(.vertical, 6)
        }
    }
}

struct SafariWebView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIViewController {
        let safariVC = SFSafariViewController(url: url)
        return safariVC
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    // This would typically use SFSafariViewController, but we'll just declare it
    // for the sake of the example as it requires importing SafariServices
    typealias SFSafariViewController = UIViewController
}

class WebSearchViewModel: ObservableObject {
    @Published var searchResults: [SearchResult] = []
    @Published var aiSummary: String? = nil
    @Published var isLoading = false
    @Published var hasSearched = false
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var showingWebView = false
    @Published var webViewURL: URL? = nil
    
    private let webSearchService = WebSearchService()
    
    func performSearch(query: String) {
        isLoading = true
        searchResults = []
        aiSummary = nil
        
        webSearchService.search(query: query) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.hasSearched = true
                
                switch result {
                case .success(let searchResponse):
                    self?.searchResults = searchResponse.results
                    self?.aiSummary = searchResponse.aiSummary
                case .failure(let error):
                    self?.showError(message: error.localizedDescription)
                }
            }
        }
    }
    
    func openWebPage(url: String) {
        guard let url = URL(string: url) else {
            showError(message: "Invalid URL")
            return
        }
        
        webViewURL = url
        showingWebView = true
    }
    
    private func showError(message: String) {
        errorMessage = message
        showingError = true
    }
}

struct SearchResult: Identifiable {
    let id = UUID()
    let title: String
    let url: String
    let description: String
}

struct WebSearchView_Previews: PreviewProvider {
    static var previews: some View {
        WebSearchView()
    }
}
