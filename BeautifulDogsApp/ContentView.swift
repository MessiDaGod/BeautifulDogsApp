import SwiftUI
import AVKit

class Cart: ObservableObject {
    struct CartItem: Identifiable {
        let id = UUID()
        var name: String
        var price: Double
    }
    
    @Published var items: [CartItem] = []
    
    func addItem(name: String, price: Double) {
        if !items.contains(where: { $0.name == name }) {
            items.append(CartItem(name: name, price: price))
        }
    }
    
    func removeItem(_ item: CartItem) {
        items.removeAll { $0.id == item.id }
    }
    
    func updatePrice(for item: CartItem, newPrice: Double) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].price = newPrice
        }
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
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 18, height: 18)
                            Text("\(cart.items.count)")
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                        .offset(x: 10, y: -10)
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
        .accentColor(isDarkMode ? .white : .black)
        .environment(\.colorScheme, isDarkMode ? .dark : .light)
        .environmentObject(cart)
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

enum AppTab: CaseIterable {
    case home, orders, account
}

struct DogGridView: View {
    @EnvironmentObject var cart: Cart
    @State private var isAdded: [String: Bool] = [:] // Track if an item has been added

    let dogItems: [String] = {
        let fileManager = FileManager.default
        let resourcePath = Bundle.main.resourcePath!
        let directoryPath = resourcePath + "/Media/Dogs"
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: directoryPath)
            
            let imageFiles = files.filter { $0.hasSuffix(".png") || $0.hasSuffix(".jpg") || $0.hasSuffix(".jpeg") }
            let videoFiles = files.filter { $0.hasSuffix(".mp4") || $0.hasSuffix(".MOV") || $0.hasSuffix(".mov") }
            
            let strippedImages = imageFiles.map { $0.replacingOccurrences(of: ".png", with: "")
                                                .replacingOccurrences(of: ".jpg", with: "")
                                                .replacingOccurrences(of: ".jpeg", with: "") }
            
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
                        NavigationLink(destination: DogDetailView(item: item, isAdded: Binding(
                            get: { cart.items.contains(where: { $0.name == item }) },
                            set: { newValue in
                                if newValue {
                                    cart.addItem(name: item, price: 5000.0) // Assuming a price here
                                } else if let cartItem = cart.items.first(where: { $0.name == item }) {
                                    cart.removeItem(cartItem)
                                }
                                isAdded[item] = newValue
                            }
                        ))) {
                            VStack {
                                if item.hasSuffix(".mp4") ||
                                    item.hasSuffix(".MOV") || item.hasSuffix(".mov") {
                                    VideoPlayerPreview(videoName: item)
                                        .frame(width: 150, height: 150)
                                        .cornerRadius(8)
                                } else {
                                    if let image = loadImage(named: item, subdirectory: "Media/Dogs") {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 150, height: 150)
                                            .cornerRadius(8)
                                            .clipped()
                                    } else {
                                        Text("Image not found")
                                            .foregroundColor(.red)
                                            .frame(width: 150, height: 150)
                                            .background(Color.gray.opacity(0.3))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        
                        if cart.items.contains(where: { $0.name == item }) {
                            Button(action: {
                                if let cartItem = cart.items.first(where: { $0.name == item }) {
                                    cart.removeItem(cartItem)
                                    isAdded[item] = false
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            .padding([.top, .trailing], 8)
                        } else {
                            Button(action: {
                                cart.addItem(name: item, price: 5000.0) // Assuming a price here
                                isAdded[item] = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            .padding([.top, .trailing], 8)
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            // Synchronize the isAdded state with the cart
            for item in dogItems {
                isAdded[item] = cart.items.contains(where: { $0.name == item })
            }
        }
    }

    func loadImage(named: String, subdirectory: String) -> UIImage? {
        if let path = Bundle.main.path(forResource: named, ofType: "png", inDirectory: subdirectory) {
            return UIImage(contentsOfFile: path)
        }
        if let path = Bundle.main.path(forResource: named, ofType: "jpeg", inDirectory: subdirectory) {
            return UIImage(contentsOfFile: path)
        }
        if let path = Bundle.main.path(forResource: named, ofType: "jpg", inDirectory: subdirectory) {
            return UIImage(contentsOfFile: path)
        }
        return nil
    }
}

struct DogDetailView: View {
    let item: String
    @Binding var isAdded: Bool
    @EnvironmentObject var cart: Cart
    @State private var price: Double = 5000.0 // Default price, change as needed
    @State private var isAdmin: Bool = false // For demonstration purposes, set to true if admin
    
    private var title: String {
        return (item as NSString).deletingPathExtension
    }

    var body: some View {
        VStack {
            let title = (item as NSString).deletingPathExtension
            
            if item.hasSuffix(".mp4") || item.hasSuffix(".MOV") || item.hasSuffix(".mov") {
                VideoPlayerView(videoName: item)
                    .navigationTitle(title)
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                if let image = loadImage(named: item, subdirectory: "Media/Dogs") {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .navigationTitle(title)
                        .navigationBarTitleDisplayMode(.inline)
                        .overlay(
                            VStack {
                                if isAdmin {
                                    TextField("Price", value: $price, format: .currency(code: "USD"))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .padding()
                                } else {
                                    Text("\(price, format: .currency(code: "USD"))")
                                        .padding()
                                }

                                Button(action: {
                                    if isAdded {
                                        removeFromCart(title: title)
                                    } else {
                                        addToCart(title: title, price: price)
                                    }
                                }) {
                                    Image(systemName: isAdded ? "minus.circle.fill" : "plus.circle.fill")
                                        .foregroundColor(isAdded ? .red : .green)
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
        .onAppear {
            isAdded = cart.items.contains(where: { $0.name == title })
        }
    }

    func addToCart(title: String, price: Double) {
        cart.addItem(name: title, price: price)
        isAdded = true
    }

    func removeFromCart(title: String) {
        if let cartItem = cart.items.first(where: { $0.name == title }) {
            cart.removeItem(cartItem)
            isAdded = false
        }
    }

    func loadImage(named: String, subdirectory: String) -> UIImage? {
        if let path = Bundle.main.path(forResource: named, ofType: "png", inDirectory: subdirectory) {
            return UIImage(contentsOfFile: path)
        }
        if let path = Bundle.main.path(forResource: named, ofType: "jpeg", inDirectory: subdirectory) {
            return UIImage(contentsOfFile: path)
        }
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
                        player?.pause()
                        player?.replaceCurrentItem(with: nil)
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

struct OrdersView: View {
    @EnvironmentObject var cart: Cart
    @State private var isAdmin: Bool = false // For demonstration purposes, set to true if admin

    var body: some View {
        List {
            ForEach(cart.items) { item in
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.name)
                            .font(.headline)
                        if isAdmin {
                            TextField("Price", value: Binding(
                                get: { item.price },
                                set: { newPrice in
                                    cart.updatePrice(for: item, newPrice: newPrice)
                                }
                            ), format: .currency(code: "USD"))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        } else {
                            Text("\(item.price, format: .currency(code: "USD"))")
                        }
                    }
                    Spacer()
                }
            }
            .onDelete { indexSet in
                indexSet.forEach { index in
                    let item = cart.items[index]
                    cart.removeItem(item)
                }
            }
        }
       // .navigationTitle("Orders")
    }
}


struct AccountView: View {
    var body: some View {
        Text("Account Screen")
            .foregroundColor(.primary)
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
