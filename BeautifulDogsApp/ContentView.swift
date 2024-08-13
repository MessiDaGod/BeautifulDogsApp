import SwiftUI
import AVKit

struct ScreenMirrorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark) // Use dark mode
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                DogGridView()
                    .navigationBarTitle("Beautiful Dogs")
                    .navigationBarTitleDisplayMode(.inline)
                    .background(Color.black) // Set background to black
            }
            .tabItem {
                Image(systemName: "pawprint.fill")
                Text("Home")
            }
            .tag(AppTab.home)
            .background(Color.black) // Set background to black
            
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .tag(AppTab.search)
                .background(Color.black) // Set background to black
            
            OrdersView()
                .tabItem {
                    Image(systemName: "cart.fill")
                    Text("Orders")
                }
                .tag(AppTab.orders)
                .background(Color.black) // Set background to black
            
            AccountView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Account")
                }
                .tag(AppTab.account)
                .background(Color.black) // Set background to black
        }
        .accentColor(.white) // Set tab bar icons to white
    }
}

enum AppTab: CaseIterable {
    case home, search, orders, account
}

struct DogGridView: View {
    let dogItems: [String] = {
        let fileManager = FileManager.default
        let resourcePath = Bundle.main.resourcePath!
        let directoryPath = resourcePath + "/Media/Dogs"
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: directoryPath)
            let filteredFiles = files.filter { $0.hasSuffix(".png") || $0.hasSuffix(".jpg") || $0.hasSuffix(".jpeg") || $0.hasSuffix(".mp4") }
            print("Files found: \(filteredFiles)") // Debugging line to see the files found
            return filteredFiles.map { $0.replacingOccurrences(of: ".png", with: "")
                                    .replacingOccurrences(of: ".jpg", with: "")
                                    .replacingOccurrences(of: ".jpeg", with: "")
                                    .replacingOccurrences(of: ".mp4", with: "") }
        } catch {
            print("Error loading contents of directory: \(error)")
            return []
        }
    }()

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(dogItems, id: \.self) { item in
                    NavigationLink(destination: DogDetailView(item: item)) {
                        VStack {
                            if item.contains("Video") {
                                VideoPlayerPreview(videoName: item)
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(8)
                            } else {
                                if let image = loadImage(named: item, subdirectory: "Media/Dogs") {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(8)
                                        .clipped()
                                } else {
                                    Text("Image not found")
                                        .foregroundColor(.red)
                                        .frame(width: 100, height: 100)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color.black) // Set background to black
        }
        .background(Color.black) // Set background to black
    }

    func loadImage(named: String, subdirectory: String) -> UIImage? {
        guard let path = Bundle.main.path(forResource: named, ofType: "png", inDirectory: subdirectory) else {
            print("Image \(named).png not found in \(subdirectory)") // Debugging line
            return nil
        }
        print("Loaded image from path: \(path)") // Debugging line
        return UIImage(contentsOfFile: path)
    }
}

struct VideoPlayerPreview: View {
    let videoName: String

    var body: some View {
        if let url = Bundle.main.url(forResource: videoName, withExtension: "mp4", subdirectory: "Media/Dogs") {
            VideoPlayer(player: AVPlayer(url: url))
                .onAppear {
                    AVPlayer(url: url).play() // Automatically play the video preview
                }
        } else {
            Text("Video not found")
                .foregroundColor(.red)
                .frame(width: 100, height: 100)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(8)
        }
    }
}

struct DogDetailView: View {
    let item: String

    var body: some View {
        VStack {
            if item.contains("Video") {
                VideoPlayerView(videoName: item)
                    .navigationTitle(item) // Set the title to the name of the video
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                if let image = loadImage(named: item, subdirectory: "Media/Dogs") {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .navigationTitle(item) // Set the title to the name of the image
                        .navigationBarTitleDisplayMode(.inline)
                } else {
                    Text("Image not found")
                        .foregroundColor(.red)
                        .navigationTitle("Error")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .background(Color.black) // Set background to black
    }

    func loadImage(named: String, subdirectory: String) -> UIImage? {
        guard let path = Bundle.main.path(forResource: named, ofType: "png", inDirectory: subdirectory) else {
            return nil
        }
        return UIImage(contentsOfFile: path)
    }
}

struct VideoPlayerView: View {
    let videoName: String

    var body: some View {
        GeometryReader { geometry in
            if let url = Bundle.main.url(forResource: videoName, withExtension: "mp4", subdirectory: "Media/Dogs") {
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(Color.black)
            } else {
                Text("Video not found")
                    .foregroundColor(.red)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(Color.black) // Set background to black
            }
        }
        .background(Color.black) // Set background to black
    }
}

struct SearchView: View {
    var body: some View {
        Text("Search Screen")
            .foregroundColor(.white) // Set text to white
            .background(Color.black) // Set background to black
    }
}

struct OrdersView: View {
    var body: some View {
        Text("Orders Screen")
            .foregroundColor(.white) // Set text to white
            .background(Color.black) // Set background to black
    }
}

struct AccountView: View {
    var body: some View {
        Text("Account Screen")
            .foregroundColor(.white) // Set text to white
            .background(Color.black) // Set background to black
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
