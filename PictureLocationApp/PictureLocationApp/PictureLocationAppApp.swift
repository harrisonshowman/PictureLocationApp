//
//  PictureLocationAppApp.swift
//  PictureLocationApp
//
//  Created by Harrison Showman on 6/29/25.
//

import SwiftUI
import SwiftData

@main
struct PictureLocationAppApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PhotoItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
            .onAppear {
                LocationManager.shared.requestLocation()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
