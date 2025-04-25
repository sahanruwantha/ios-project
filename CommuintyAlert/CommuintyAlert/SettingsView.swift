import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var locationEnabled = true
    @Environment(\.dismiss) var dismiss
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.system(size: 24, weight: .semibold))
                .padding(.top)
            
            ScrollView {
                VStack(spacing: 15) {
                    // Notifications
                    HStack {
                        Text("Notifications")
                            .font(.system(size: 16))
                        Spacer()
                        Toggle("", isOn: $notificationsEnabled)
                            .labelsHidden()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    
                    // Location Services
                    HStack {
                        Text("Location Services")
                            .font(.system(size: 16))
                        Spacer()
                        Toggle("", isOn: $locationEnabled)
                            .labelsHidden()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    
                    // Alert Preferences
                    NavigationLink(destination: AlertPreferencesView()) {
                        HStack {
                            Text("Alert Preferences")
                                .font(.system(size: 16))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                    }
                    
                    // Privacy
                    NavigationLink(destination: PrivacyView()) {
                        HStack {
                            Text("Privacy")
                                .font(.system(size: 16))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                    }
                    
                    // About
                    NavigationLink(destination: AboutView()) {
                        HStack {
                            Text("About")
                                .font(.system(size: 16))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Logout 
            Button(action: {
                // Handle logout
                UserDefaults.standard.removeObject(forKey: "token")
                UserDefaults.standard.removeObject(forKey: "refreshToken")
                UserDefaults.standard.removeObject(forKey: "userId")
                isLoggedIn = false
                dismiss()
            }) {
                Text("Log Out")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(25)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

struct AlertPreferencesView: View {
    var body: some View {
        Text("Alert Preferences")
            .navigationTitle("Alert Preferences")
    }
}

struct PrivacyView: View {
    var body: some View {
        Text("Privacy")
            .navigationTitle("Privacy")
    }
}

struct AboutView: View {
    var body: some View {
        Text("About")
            .navigationTitle("About")
    }
}

#Preview {
    SettingsView()
} 