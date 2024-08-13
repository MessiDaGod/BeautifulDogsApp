//
//  BeautifulDogsAppApp.swift
//  BeautifulDogsApp
//
//  Created by Joe Shakely on 8/13/24.
//

import SwiftUI

@main
struct BeautifulDogsAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
