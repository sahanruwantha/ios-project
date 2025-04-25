import CoreData
import SwiftUI

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "CommuintyAlert")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
    
    
    // Saves a new alert to the local history database
    // This helps track which alerts the user has interacted with
    func saveAlert(_ alert: Alert) {
        let alertHistory = AlertHistory(context: container.viewContext)
        alertHistory.id = alert.id
        alertHistory.title = alert.title
        alertHistory.alertDescription = alert.description
        alertHistory.alertType = alert.category.rawValue
        alertHistory.latitude = alert.location.latitude
        alertHistory.longitude = alert.location.longitude
        alertHistory.createdAt = Date()
        
        save()
    }
    
    // Retrieves the user's complete alert history from local storage
    // Returns an array of past alerts sorted by date
    func fetchAlertHistory() -> [AlertHistory] {
        let request = NSFetchRequest<AlertHistory>(entityName: "AlertHistory")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AlertHistory.createdAt, ascending: false)]
        
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Failed to fetch alert history: \(error)")
            return []
        }
    }
    
    
    // Persists user preferences and settings to CoreData
    // These settings persist even when the user logs out
    func saveUserSettings(userId: String, colorScheme: Int16, notificationsEnabled: Bool) {
        let request = NSFetchRequest<UserSettings>(entityName: "UserSettings")
        request.predicate = NSPredicate(format: "userId == %@", userId)
        
        do {
            let results = try container.viewContext.fetch(request)
            let settings: UserSettings
            
            if let existingSettings = results.first {
                settings = existingSettings
            } else {
                settings = UserSettings(context: container.viewContext)
                settings.userId = userId
            }
            
            settings.colorScheme = colorScheme
            settings.notificationsEnabled = notificationsEnabled
            
            save()
        } catch {
            print("Failed to save user settings: \(error)")
        }
    }
    
    // Retrieves stored settings for a specific user
    // Returns nil if no settings exist for the user
    func getUserSettings(userId: String) -> UserSettings? {
        let request = NSFetchRequest<UserSettings>(entityName: "UserSettings")
        request.predicate = NSPredicate(format: "userId == %@", userId)
        
        do {
            let results = try container.viewContext.fetch(request)
            return results.first
        } catch {
            print("Failed to fetch user settings: \(error)")
            return nil
        }
    }
    
    
    // Commits any pending changes to CoreData
    // Called internally after any data modifications
    private func save() {
        do {
            try container.viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
