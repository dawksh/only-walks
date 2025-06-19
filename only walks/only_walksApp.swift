//
//  only_walksApp.swift
//  only walks
//
//  Created by Daksh Kulshrestha on 19/06/25.
//

import SwiftUI

final class CoreDataStack: ObservableObject {}

@main
struct only_walksApp: App {
    @StateObject var coreDataStack = CoreDataStack()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coreDataStack)
        }
    }
}
