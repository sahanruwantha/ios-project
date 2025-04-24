import Foundation
import CoreLocation
import MapKit
import PhotosUI
import LocalAuthentication

// Alert Types
enum AlertCategory: String, CaseIterable, Codable {
    case weather = "Weather"
    case traffic = "Traffic"
    case crime = "Crime"
    case community = "Community"
    case publicSafety = "Public Safety"
    case infrastructure = "Infrastructure"
}

enum AlertPriority: String, Codable {
    case immediate = "Immediate"
    case important = "Important"
    case informational = "Informational"
}

enum VerificationStatus: String, Codable {
    case verified = "Verified"
    case pending = "Pending"
    case unverified = "Unverified"
}

// Alert Model
struct Alert: Identifiable, Codable, MapItem {
    let id: String
    let title: String
    let description: String
    let category: AlertCategory
    let priority: AlertPriority
    let verificationStatus: VerificationStatus
    let location: Location
    let radius: CLLocationDistance
    let timestamp: Date
    let source: String
    let isActive: Bool
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case category
        case priority
        case verificationStatus = "verification_status"
        case location
        case radius
        case timestamp
        case source
        case isActive = "is_active"
        case userId = "user_id"
    }
    
    // Custom initializer for creating new alerts
    init(id: String, title: String, description: String, category: AlertCategory, priority: AlertPriority, verificationStatus: VerificationStatus, location: Location, radius: CLLocationDistance, timestamp: Date, source: String, isActive: Bool, userId: String) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.verificationStatus = verificationStatus
        self.location = location
        self.radius = radius
        self.timestamp = timestamp
        self.source = source
        self.isActive = isActive
        self.userId = userId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        category = try container.decode(AlertCategory.self, forKey: .category)
        priority = try container.decode(AlertPriority.self, forKey: .priority)
        verificationStatus = try container.decode(VerificationStatus.self, forKey: .verificationStatus)
        location = try container.decode(Location.self, forKey: .location)
        radius = try container.decode(CLLocationDistance.self, forKey: .radius)
        source = try container.decode(String.self, forKey: .source)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        userId = try container.decode(String.self, forKey: .userId)
        
        // Custom date decoding with support for microseconds
        let dateString = try container.decode(String.self, forKey: .timestamp)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        if let date = dateFormatter.date(from: dateString) {
            timestamp = date
        } else {
            // Fallback to ISO8601DateFormatter if the first attempt fails
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                timestamp = date
            } else {
                throw DecodingError.dataCorruptedError(forKey: .timestamp, in: container, debugDescription: "Invalid date format: \(dateString)")
            }
        }
    }
    
    struct Location: Codable {
        let latitude: Double
        let longitude: Double
        
        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
}

extension Alert {
    var coordinate: CLLocationCoordinate2D { location.coordinate }
    var displayTitle: String { title }
}

// User Preferences
struct UserPreferences: Codable {
    var enabledCategories: Set<AlertCategory>
    var alertRadius: CLLocationDistance
    var notificationSettings: NotificationSettings
    var emergencyContacts: [EmergencyContact]
}

struct NotificationSettings: Codable {
    var soundEnabled: Bool
    var vibrationEnabled: Bool
    var criticalAlertsEnabled: Bool
    var communityAlertsEnabled: Bool
}

struct EmergencyContact: Codable, Identifiable {
    let id: String
    let name: String
    let phoneNumber: String
    let relationship: String
}

// Community Resource
struct CommunityResource: Identifiable, Codable, MapItem {
    let id: String
    let name: String
    let type: ResourceType
    let location: Alert.Location
    let description: String
    let contactInfo: String
}

extension CommunityResource {
    var coordinate: CLLocationCoordinate2D { location.coordinate }
    var displayTitle: String { name }
}

enum ResourceType: String, Codable {
    case shelter = "Shelter"
    case hospital = "Hospital"
    case policeStation = "Police Station"
    case fireStation = "Fire Station"
    case communityCenter = "Community Center"
}

// User Model
struct User: Codable {
    let id: String
    let email: String
    let fullName: String
    let phoneNumber: String
    let avatarUrl: String?
    let createdAt: Date
    let lastLogin: Date
}

// Remove dummy data as we'll be using real data from the API 