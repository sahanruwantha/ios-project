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
    
    // MARK: - Alert History Methods
    
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
    
    // MARK: - User Settings Methods
    
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
    
    // MARK: - Utility Methods
    
    private func save() {
        do {
            try container.viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
