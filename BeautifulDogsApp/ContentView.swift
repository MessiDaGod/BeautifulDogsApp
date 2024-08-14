import SwiftUI
import AVKit

class Cart: ObservableObject {
    @Published var items: [String] = []
    
    func addItem(_ item: String) {
        if !items.contains(item) {
            items.append(item)
        }
    }
    
    func removeItem(_ item: String) {
        items.removeAll { $0 == item }
    }
}

struct ScreenMirrorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var isDarkMode: Bool = true // Track the current mode
    @StateObject var cart = Cart() // Create a Cart object to track items

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                CustomNavigationBar(title: "Beautiful Dogs", isDarkMode: $isDarkMode) {
                    DogGridView()
                        .environmentObject(cart)
                }
                .environment(\.colorScheme, isDarkMode ? .dark : .light)
            }
            .tabItem {
                Image(systemName: "pawprint.fill")
                Text("Home")
            }
            .tag(AppTab.home)
            
            NavigationView {
                CustomNavigationBar(title: "Orders", isDarkMode: $isDarkMode) {
                    OrdersView()
                        .environmentObject(cart)
                }
                .environment(\.colorScheme, isDarkMode ? .dark : .light)
            }
            .tabItem {
                ZStack {
                    Image(systemName: "cart.fill")
                    if cart.items.count > 0 {
                        // This ZStack is used to ensure the badge appears correctly on top of the cart icon
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 18, height: 18) // Ensures the badge is a red circle
                            Text("\(cart.items.count)")
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                        .offset(x: 10, y: -10) // Position the badge in the top right corner
                    }
                }
                Text("Orders")
            }
            .tag(AppTab.orders)
            
            NavigationView {
                CustomNavigationBar(title: "Account", isDarkMode: $isDarkMode) {
                    AccountView()
                }
                .environment(\.colorScheme, isDarkMode ? .dark : .light)
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("Account")
            }
            .tag(AppTab.account)
        }
        .accentColor(isDarkMode ? .white : .black) // Adjust the accent color based on theme
        .environment(\.colorScheme, isDarkMode ? .dark : .light) // Apply the current theme globally
        .environmentObject(cart) // Provide the Cart object to the entire ContentView hierarchy
    }
}


struct CustomNavigationBar<Content: View>: View {
    let title: String
    @Binding var isDarkMode: Bool
    let content: Content
    
    init(title: String, isDarkMode: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.title = title
        self._isDarkMode = isDarkMode
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: {
                    isDarkMode.toggle()
                }) {
                    Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure content takes up remaining space
                .background(Color(.systemBackground))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure the entire view fills the screen
    }
}

enum AppTab: CaseIterable {
    case home,/* search, */orders, account
}

struct DogGridView: View {
    @State private var orderCounts: [String: Int] = [:] // Track the number of orders for each item

    let dogItems: [String] = {
        let fileManager = FileManager.default
        let resourcePath = Bundle.main.resourcePath!
        let directoryPath = resourcePath + "/Media/Dogs"
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: directoryPath)
            
            // Separate images from videos
            let imageFiles = files.filter { $0.hasSuffix(".png") || $0.hasSuffix(".jpg") || $0.hasSuffix(".jpeg") }
            let videoFiles = files.filter { $0.hasSuffix(".mp4") || $0.hasSuffix(".MOV") || $0.hasSuffix(".mov") }
            
            // Strip extensions for image files only
            let strippedImages = imageFiles.map { $0.replacingOccurrences(of: ".png", with: "")
                                                .replacingOccurrences(of: ".jpg", with: "")
                                                .replacingOccurrences(of: ".jpeg", with: "") }
            
            // Return a combined list of image and video files
            return strippedImages + videoFiles
        } catch {
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
                    ZStack(alignment: .topTrailing) {
                        NavigationLink(destination: DogDetailView(item: item, orderCounts: $orderCounts)) {
                            VStack {
                                if item.hasSuffix(".mp4") || item.hasSuffix(".MOV") || item.hasSuffix(".mov") {
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
            }
            .padding()
        }
    }

    func loadImage(named: String, subdirectory: String) -> UIImage? {
        // Check for PNG first
        if let path = Bundle.main.path(forResource: named, ofType: "png", inDirectory: subdirectory) {
            return UIImage(contentsOfFile: path)
        }
        // Check for JPEG
        if let path = Bundle.main.path(forResource: named, ofType: "jpeg", inDirectory: subdirectory) {
            return UIImage(contentsOfFile: path)
        }
        // Check for JPG
        if let path = Bundle.main.path(forResource: named, ofType: "jpg", inDirectory: subdirectory) {
            return UIImage(contentsOfFile: path)
        }
        return nil
    }
}

struct VideoPlayerPreview: View {
    let videoName: String

    var body: some View {
        if let url = Bundle.main.url(forResource: videoName, withExtension: nil, subdirectory: "Media/Dogs") {
            VideoPlayer(player: AVPlayer(url: url))
                .frame(width: 100, height: 100)
                .cornerRadius(8)
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
    @Binding var orderCounts: [String: Int]
    @EnvironmentObject var cart: Cart

    var body: some View {
        VStack {
            let title = (item as NSString).deletingPathExtension // Strip the extension for the title
            
            if item.hasSuffix(".mp4") || item.hasSuffix(".MOV") || item.hasSuffix(".mov") {
                VideoPlayerView(videoName: item)
                    .navigationTitle(title)  // Use the title without extension
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                if let image = loadImage(named: item, subdirectory: "Media/Dogs") {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .navigationTitle(title)  // Use the title without extension
                        .navigationBarTitleDisplayMode(.inline)
                        .overlay(
                            VStack {
                                Button(action: {
                                    orderCounts[item, default: 0] += 1
                                    cart.addItem(item)
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.green)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                }
                                .padding([.top, .trailing], 8)
                            }
                            .padding(),
                            alignment: .topTrailing
                        )
                } else {
                    Text("Image not found")
                        .foregroundColor(.red)
                        .navigationTitle("Error")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }

    func loadImage(named: String, subdirectory: String) -> UIImage? {
        // Check for PNG first
        if let path = Bundle.main.path(forResource: named, ofType: "png", inDirectory: subdirectory) {
            return UIImage(contentsOfFile: path)
        }
        // Check for JPEG
        if let path = Bundle.main.path(forResource: named, ofType: "jpeg", inDirectory: subdirectory) {
            return UIImage(contentsOfFile: path)
        }
        // Check for JPG
        if let path = Bundle.main.path(forResource: named, ofType: "jpg", inDirectory: subdirectory) {
            return UIImage(contentsOfFile: path)
        }
        return nil
    }
}


struct VideoPlayerView: View {
    let videoName: String
    @State private var player: AVPlayer?

    var body: some View {
        GeometryReader { geometry in
            if let url = Bundle.main.url(forResource: videoName, withExtension: nil, subdirectory: "Media/Dogs") {
                VideoPlayer(player: player ?? AVPlayer(url: url))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .onAppear {
                        player = AVPlayer(url: url)
                    }
                    .onDisappear {
                        player?.pause()  // Pause the video when the view disappears
                        player?.replaceCurrentItem(with: nil)  // Optionally, release the player
                    }
            } else {
                Text("Video not found")
                    .foregroundColor(.red)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(Color.gray.opacity(0.3))
            }
        }
    }
}


struct SearchView: View {
    var body: some View {
        Text("Search Screen")
            .foregroundColor(.primary) // Adapt to the current theme
    }
}

struct OrdersView: View {
    var body: some View {
        Text("Orders Screen")
            .foregroundColor(.primary) // Adapt to the current theme
    }
}

struct AccountView: View {
    var body: some View {
        Text("Account Screen")
            .foregroundColor(.primary) // Adapt to the current theme
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
