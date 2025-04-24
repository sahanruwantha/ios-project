import Foundation
import CoreLocation

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case unauthorized
    case badRequest(String)
}

class NetworkService {
    static let shared = NetworkService()
    private let baseURL = "http://localhost:3000/api"
    private var authToken: String?
    
    private init() {
        // Load token from UserDefaults during initialization
        self.authToken = UserDefaults.standard.string(forKey: "token")
    }
    
    // Add method to update token
    func updateAuthToken(_ token: String) {
        self.authToken = token
        UserDefaults.standard.set(token, forKey: "token")
    }
    
    // MARK: - Authentication
    
    func register(email: String, password: String, fullName: String, phoneNumber: String) async throws -> AuthResponse {
        let endpoint = "\(baseURL)/auth/register"
        let body = [
            "email": email,
            "password": password,
            "full_name": fullName,
            "phone_number": phoneNumber
        ]
        
        return try await performRequest(endpoint: endpoint, method: "POST", body: body)
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let endpoint = "\(baseURL)/auth/login"
        guard var urlComponents = URLComponents(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        // Add query parameters
        urlComponents.queryItems = [
            URLQueryItem(name: "email", value: email),
            URLQueryItem(name: "password", value: password)
        ]
        
        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }
        
        let response: AuthResponse = try await performRequest(endpoint: url.absoluteString, method: "POST", body: nil)
        print("Debug: Login response - access token: \(response.accessToken)")  // Debug line
        return response
    }
    
    func refreshToken() async throws -> AuthResponse {
        guard let refreshToken = UserDefaults.standard.string(forKey: "refreshToken") else {
            throw NetworkError.unauthorized
        }
        
        let endpoint = "\(baseURL)/auth/refresh-token"
        let body = ["refreshToken": refreshToken]
        
        return try await performRequest(endpoint: endpoint, method: "POST", body: body)
    }
    
    // MARK: - Alerts
    
    func getAlerts(latitude: Double? = nil, longitude: Double? = nil, radius: Double? = nil) async throws -> [Alert] {
        var endpoint = "\(baseURL)/alerts"
        if let lat = latitude, let lon = longitude, let rad = radius {
            endpoint += "?latitude=\(lat)&longitude=\(lon)&radius=\(rad)"
        }
        
        return try await performRequest(endpoint: endpoint, method: "GET")
    }
    
    func createAlert(alert: Alert) async throws -> Alert {
        let endpoint = "\(baseURL)/alerts"
        let body: [String: Any] = [
            "title": alert.title,
            "description": alert.description,
            "category": alert.category.rawValue,
            "priority": alert.priority.rawValue,
            "location": [
                "latitude": alert.location.latitude,
                "longitude": alert.location.longitude
            ],
            "radius": alert.radius,
            "source": alert.source
        ]
        
        return try await performRequest(endpoint: endpoint, method: "POST", body: body)
    }
    
    // MARK: - User Preferences
    
    func getUserPreferences() async throws -> UserPreferences {
        let userId = try getUserId()
        let endpoint = "\(baseURL)/users/\(userId)/preferences"
        
        return try await performRequest(endpoint: endpoint, method: "GET")
    }
    
    func updateUserPreferences(preferences: UserPreferences) async throws -> UserPreferences {
        let userId = try getUserId()
        let endpoint = "\(baseURL)/users/\(userId)/preferences"
        let body: [String: Any] = [
            "enabledCategories": Array(preferences.enabledCategories.map { $0.rawValue }),
            "alertRadius": preferences.alertRadius,
            "notificationSettings": [
                "soundEnabled": preferences.notificationSettings.soundEnabled,
                "vibrationEnabled": preferences.notificationSettings.vibrationEnabled,
                "criticalAlertsEnabled": preferences.notificationSettings.criticalAlertsEnabled,
                "communityAlertsEnabled": preferences.notificationSettings.communityAlertsEnabled
            ]
        ]
        
        return try await performRequest(endpoint: endpoint, method: "PUT", body: body)
    }
    
    // MARK: - Community Resources
    
    func getCommunityResources(latitude: Double, longitude: Double, radius: Double) async throws -> [CommunityResource] {
        let endpoint = "\(baseURL)/resources/nearby?latitude=\(latitude)&longitude=\(longitude)&radius=\(radius)"
        return try await performRequest(endpoint: endpoint, method: "GET")
    }
    
    // MARK: - Helper Methods
    
    private func getUserId() throws -> String {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            throw NetworkError.unauthorized
        }
        return userId
    }
    
    private func performRequest<T: Decodable>(endpoint: String, method: String, body: [String: Any]? = nil) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("Debug: Setting Authorization header with token: Bearer \(token)")
        } else {
            print("Debug: No auth token available")
        }
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError("Invalid response")
        }
        
        // Debug response
        print("Debug: Response status code: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("Debug: Response body: \(responseString)")
        }
        
        // Try to decode error response first
        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            throw NetworkError.serverError(errorResponse.detail)
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                print("Debug: Decoding error: \(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Debug: Failed to decode response: \(responseString)")
                }
                throw NetworkError.decodingError
            }
        case 401:
            throw NetworkError.unauthorized
        case 400:
            if let errorMessage = String(data: data, encoding: .utf8) {
                throw NetworkError.badRequest(errorMessage)
            }
            throw NetworkError.badRequest("Bad request")
        default:
            if let errorMessage = String(data: data, encoding: .utf8) {
                throw NetworkError.serverError("Server error (\(httpResponse.statusCode)): \(errorMessage)")
            }
            throw NetworkError.serverError("Server error: \(httpResponse.statusCode)")
        }
    }
}

// MARK: - Response Models

struct AuthResponse: Codable {
    let userId: String
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

struct ErrorResponse: Codable {
    let detail: String
} 