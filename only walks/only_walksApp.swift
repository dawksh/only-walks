//
//  only_walksApp.swift
//  only walks
//
//  Created by Daksh Kulshrestha on 19/06/25.
//

import SwiftUI

final class CoreDataStack: ObservableObject {}
final class AuthState: ObservableObject {
    @Published var isAuthenticated = false
}

@main
struct only_walksApp: App {
    @StateObject var coreDataStack = CoreDataStack()
    @StateObject var authState = AuthState()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coreDataStack)
                .environmentObject(authState)
        }
    }
}
