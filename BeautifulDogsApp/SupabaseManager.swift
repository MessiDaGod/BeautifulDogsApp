import Foundation
import Combine
import Supabase

class SupabaseManager: ObservableObject {
    let client: SupabaseClient

    init(url: String, key: String) {
        self.client = SupabaseClient(supabaseURL: URL(string: url)!, supabaseKey: key)
    }

    // Add any additional methods you need to interact with your SupabaseClient
}
