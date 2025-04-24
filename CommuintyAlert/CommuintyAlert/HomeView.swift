import SwiftUI
import MapKit

// Create a protocol for map items
protocol MapItem: Identifiable {
    var coordinate: CLLocationCoordinate2D { get }
    var displayTitle: String { get }
}

struct HomeView: View {
    @State private var alerts: [Alert] = []
    @State private var selectedAlert: Alert?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    @StateObject private var locationManager = LocationManager()
    @StateObject private var soundManager = SoundManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Map Section
            ZStack {
                Map(coordinateRegion: $region, annotationItems: alerts) { alert in
                    MapAnnotation(coordinate: alert.coordinate) {
                        AlertAnnotationView(alert: alert)
                            .onTapGesture {
                                selectedAlert = alert
                            }
                    }
                }
                .frame(height: 300)
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            Task {
                                await fetchAlerts()
                            }
                        }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title2)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                        .disabled(isLoading)
                        .padding(.trailing)
                    }
                    .padding(.top)
                    Spacer()
                }
            }
            
            // Alerts List Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Current Alerts")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    Text("\(alerts.count) active")
                        .foregroundColor(.gray)
                        .padding(.trailing)
                }
                .padding(.top)
                
                if alerts.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No active alerts")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(alerts) { alert in
                                AlertListItem(alert: alert)
                                    .onTapGesture {
                                        selectedAlert = alert
                                        // Center map on selected alert
                                        withAnimation {
                                            region.center = alert.coordinate
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .background(Color(.systemBackground))
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .task {
            await fetchAlerts()
        }
    }
    
    private func fetchAlerts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let location = locationManager.location {
                let newAlerts = try await NetworkService.shared.getAlerts(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    radius: 5000 // 5km radius
                )
                
                await MainActor.run {
                    // Play sound for new immediate alerts
                    for alert in newAlerts {
                        if !alerts.contains(where: { $0.id == alert.id }) {
                            soundManager.playAlertSound(for: alert.priority)
                            break // Only play sound for the highest priority new alert
                        }
                    }
                    
                    alerts = newAlerts
                    
                    // Update map region to show all alerts
                    if !alerts.isEmpty {
                        let coordinates = alerts.map { $0.coordinate }
                        region = MKCoordinateRegion(
                            center: coordinates[0],
                            span: MKCoordinateSpan(
                                latitudeDelta: 0.1,
                                longitudeDelta: 0.1
                            )
                        )
                    }
                }
            } else {
                errorMessage = "Location services are not available. Please enable location services in your device settings."
                showError = true
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
}

struct AlertListItem: View {
    let alert: Alert
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: alertIcon)
                    .foregroundColor(alertColor)
                Text(alert.title)
                    .font(.headline)
                Spacer()
                Text(alert.category.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(alertColor.opacity(0.2))
                    .foregroundColor(alertColor)
                    .cornerRadius(8)
            }
            
            Text(alert.description)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(2)
            
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.gray)
                Text(alert.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Image(systemName: "location")
                    .foregroundColor(.gray)
                Text("\(Int(alert.radius/1000))km")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var alertIcon: String {
        switch alert.category {
        case .weather: return "cloud.bolt.fill"
        case .traffic: return "car.fill"
        case .crime: return "exclamationmark.triangle.fill"
        case .community: return "person.3.fill"
        case .publicSafety: return "shield.fill"
        case .infrastructure: return "hammer.fill"
        }
    }
    
    private var alertColor: Color {
        switch alert.priority {
        case .immediate: return .red
        case .important: return .orange
        case .informational: return .blue
        }
    }
}

struct AlertAnnotationView: View {
    let alert: Alert
    
    var body: some View {
        VStack {
            Image(systemName: alertIcon)
                .font(.title2)
                .foregroundColor(alertColor)
                .padding(8)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(radius: 3)
        }
    }
    
    private var alertIcon: String {
        switch alert.category {
        case .weather: return "cloud.bolt.fill"
        case .traffic: return "car.fill"
        case .crime: return "exclamationmark.triangle.fill"
        case .community: return "person.3.fill"
        case .publicSafety: return "shield.fill"
        case .infrastructure: return "hammer.fill"
        }
    }
    
    private var alertColor: Color {
        switch alert.priority {
        case .immediate: return .red
        case .important: return .orange
        case .informational: return .blue
        }
    }
}

struct AlertCard: View {
    let alert: Alert
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(alert.title)
                    .font(.headline)
                Spacer()
                Text(alert.category.rawValue)
                    .font(.subheadline)
                    .padding(5)
                    .background(alertColor.opacity(0.2))
                    .foregroundColor(alertColor)
                    .cornerRadius(5)
            }
            
            Text(alert.description)
                .font(.body)
            
            HStack {
                Image(systemName: "clock")
                Text(alert.timestamp, style: .relative)
                Spacer()
                Text(alert.source)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
    
    private var alertColor: Color {
        switch alert.priority {
        case .immediate: return .red
        case .important: return .orange
        case .informational: return .blue
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        #if targetEnvironment(simulator)
        // Use a default location for simulator (San Francisco)
        location = CLLocation(latitude: 37.7749, longitude: -122.4194)
        #else
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        #endif
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }
}

#Preview {
    HomeView()
} 
