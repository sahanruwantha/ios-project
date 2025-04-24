//
//  CommuintyAlertApp.swift
//  CommuintyAlert
//
//  Created by user278242 on 4/21/25.
//

import SwiftUI
import CoreData

@main
struct CommuintyAlertApp: App {
    @StateObject private var coreDataManager = CoreDataManager.shared
    @AppStorage("userId") private var userId: String = ""
    @State private var colorScheme: ColorScheme = .light
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataManager.container.viewContext)
                .preferredColorScheme(colorScheme)
                .onAppear {
                    if let settings = coreDataManager.getUserSettings(userId: userId) {
                        colorScheme = ColorScheme(rawValue: Int(settings.colorScheme)) ?? .light
                    }
                }
        }
    }
}

extension ColorScheme {
    var toInt16: Int16 {
        switch self {
        case .light: return 0
        case .dark: return 1
        @unknown default: return 0
        }
    }
    
    init?(rawValue: Int) {
        switch rawValue {
        case 0: self = .light
        case 1: self = .dark
        default: return nil
        }
    }
}
