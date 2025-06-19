//
//  only_walksApp.swift
//  only walks
//
//  Created by Daksh Kulshrestha on 19/06/25.
//

import SwiftUI
import CoreData

final class CoreDataStack: ObservableObject {
    let container: NSPersistentContainer
    var context: NSManagedObjectContext { container.viewContext }
    init() {
        container = NSPersistentContainer(name: "WalkModel")
        container.loadPersistentStores { _, _ in }
    }
    func save() {
        try? context.save()
    }
}

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
