import SwiftUI

struct ProfileView: View {
    @State private var user: User?
    @State private var preferences: UserPreferences?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var showSettings = false
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    
    var body: some View {
        NavigationView {
            List {
                if let user = user {
                    UserProfileHeader(user: user)
                    
                    if let preferences = preferences {
                        EmergencyContactsSection(contacts: preferences.emergencyContacts)
                        
                        NotificationSettingsSection(
                            preferences: preferences,
                            onUpdate: updatePreferences
                        )
                        
                        AlertCategoriesSection(
                            preferences: preferences,
                            onUpdate: updatePreferences
                        )
                    }
                    
                    LogoutSection(logout: logout)
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
        .task {
            await loadUserData()
        }
    }
    
    private func loadUserData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // TODO: Implement getUser and getUserPreferences in NetworkService
            // For now, using placeholder data
            let userResult = User(
                id: "1",
                email: "john@example.com",
                fullName: "John Doe",
                phoneNumber: "+1234567890",
                avatarUrl: nil,
                createdAt: Date(),
                lastLogin: Date()
            )
            let preferencesResult = UserPreferences(
                enabledCategories: Set<AlertCategory>(),
                alertRadius: 5.0, // 5 kilometers
                notificationSettings: NotificationSettings(
                    soundEnabled: true,
                    vibrationEnabled: true,
                    criticalAlertsEnabled: true,
                    communityAlertsEnabled: true
                ),
                emergencyContacts: []
            )
            
            await MainActor.run {
                self.user = userResult
                self.preferences = preferencesResult
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
    
    private func updatePreferences(_ preferences: UserPreferences) async {
        do {
            _ = try await NetworkService.shared.updateUserPreferences(preferences: preferences)
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func logout() {
        UserDefaults.standard.removeObject(forKey: "token")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        UserDefaults.standard.removeObject(forKey: "userId")
        isLoggedIn = false
    }
}

// MARK: - Subviews
struct UserProfileHeader: View {
    let user: User
    
    var body: some View {
        Section {
            HStack {
                AvatarView(avatarUrl: user.avatarUrl)
                
                VStack(alignment: .leading) {
                    Text(user.fullName)
                        .font(.headline)
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct AvatarView: View {
    let avatarUrl: String?
    
    var body: some View {
        Group {
            if let avatarUrl = avatarUrl {
                AsyncImage(url: URL(string: avatarUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct EmergencyContactsSection: View {
    let contacts: [EmergencyContact]
    
    var body: some View {
        Section("Emergency Contacts") {
            ForEach(contacts) { contact in
                VStack(alignment: .leading) {
                    Text(contact.name)
                        .font(.headline)
                    Text(contact.phoneNumber)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(contact.relationship)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

struct NotificationSettingsSection: View {
    let preferences: UserPreferences
    let onUpdate: (UserPreferences) async -> Void
    
    var body: some View {
        Section("Notification Settings") {
            NotificationToggle(
                title: "Sound",
                isOn: preferences.notificationSettings.soundEnabled,
                preferences: preferences,
                onUpdate: onUpdate
            ) { prefs, value in
                var updated = prefs
                updated.notificationSettings.soundEnabled = value
                return updated
            }
            
            NotificationToggle(
                title: "Vibration",
                isOn: preferences.notificationSettings.vibrationEnabled,
                preferences: preferences,
                onUpdate: onUpdate
            ) { prefs, value in
                var updated = prefs
                updated.notificationSettings.vibrationEnabled = value
                return updated
            }
            
            NotificationToggle(
                title: "Critical Alerts",
                isOn: preferences.notificationSettings.criticalAlertsEnabled,
                preferences: preferences,
                onUpdate: onUpdate
            ) { prefs, value in
                var updated = prefs
                updated.notificationSettings.criticalAlertsEnabled = value
                return updated
            }
            
            NotificationToggle(
                title: "Community Alerts",
                isOn: preferences.notificationSettings.communityAlertsEnabled,
                preferences: preferences,
                onUpdate: onUpdate
            ) { prefs, value in
                var updated = prefs
                updated.notificationSettings.communityAlertsEnabled = value
                return updated
            }
        }
    }
}

struct NotificationToggle: View {
    let title: String
    let isOn: Bool
    let preferences: UserPreferences
    let onUpdate: (UserPreferences) async -> Void
    let updateAction: (UserPreferences, Bool) -> UserPreferences
    
    var body: some View {
        Toggle(title, isOn: Binding(
            get: { isOn },
            set: { newValue in
                let updatedPreferences = updateAction(preferences, newValue)
                Task {
                    await onUpdate(updatedPreferences)
                }
            }
        ))
    }
}

struct AlertCategoriesSection: View {
    let preferences: UserPreferences
    let onUpdate: (UserPreferences) async -> Void
    
    var body: some View {
        Section("Alert Categories") {
            ForEach(AlertCategory.allCases, id: \.self) { category in
                Toggle(category.rawValue, isOn: Binding(
                    get: { preferences.enabledCategories.contains(category) },
                    set: { isEnabled in
                        var updatedPreferences = preferences
                        if isEnabled {
                            updatedPreferences.enabledCategories.insert(category)
                        } else {
                            updatedPreferences.enabledCategories.remove(category)
                        }
                        Task {
                            await onUpdate(updatedPreferences)
                        }
                    }
                ))
            }
        }
    }
}

struct LogoutSection: View {
    let logout: () -> Void
    
    var body: some View {
        Section {
            Button("Logout") {
                logout()
            }
            .foregroundColor(.red)
        }
    }
}

struct EditProfileView: View {
    var body: some View {
        Text("Edit Profile")
            .navigationTitle("Edit Profile")
    }
}

struct SavedAlertsView: View {
    var body: some View {
        Text("Saved Alerts")
            .navigationTitle("Saved Alerts")
    }
}

struct CommunityInvolvementView: View {
    var body: some View {
        Text("Community Involvement")
            .navigationTitle("Community Involvement")
    }
}

#Preview {
    ProfileView()
} 