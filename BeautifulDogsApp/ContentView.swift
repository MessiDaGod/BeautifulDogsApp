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
                        Text("\(cart.items.count)")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 10, y: -10) // Adjust position to be top right of the cart icon
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
            let filteredFiles = files.filter { $0.hasSuffix(".png") || $0.hasSuffix(".jpg") || $0.hasSuffix(".jpeg") || $0.hasSuffix(".mp4") }
            return filteredFiles.map { $0.replacingOccurrences(of: ".png", with: "")
                                    .replacingOccurrences(of: ".jpg", with: "")
                                    .replacingOccurrences(of: ".jpeg", with: "")
                                    .replacingOccurrences(of: ".mp4", with: "") }
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
            }
            .padding()
        }
    }

    func loadImage(named: String, subdirectory: String) -> UIImage? {
        guard let path = Bundle.main.path(forResource: named, ofType: "png", inDirectory: subdirectory) else {
            return nil
        }
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
    @Binding var orderCounts: [String: Int]
    @EnvironmentObject var cart: Cart
    @State private var isAddedToCart = false // Track whether the item is added to the cart

    var body: some View {
        VStack {
            if item.contains("Video") {
                VideoPlayerView(videoName: item)
                    .navigationTitle(item)
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                if let image = loadImage(named: item, subdirectory: "Media/Dogs") {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .navigationTitle(item)
                        .navigationBarTitleDisplayMode(.inline)
                        .overlay(
                            VStack {
                                Button(action: {
                                    orderCounts[item, default: 0] += 1
                                    cart.addItem(item)
                                    isAddedToCart = true // Disable the button after adding to the cart
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.green)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                }
                                .disabled(isAddedToCart) // Disable the button once item is added
                                .opacity(isAddedToCart ? 0.5 : 1.0) // Reduce opacity if disabled
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
