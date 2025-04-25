import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false
    @State private var fullName = ""
    @State private var phoneNumber = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showBiometricAuth = false
    @State private var isAuthenticated = false
    
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("userId") private var userId = ""
    @AppStorage("useBiometrics") private var useBiometrics = false
    @AppStorage("lastEmail") private var lastEmail = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Community Alert")
                    .font(.largeTitle)
                    .bold()
                
                if isRegistering {
                    TextField("Full Name", text: $fullName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Phone Number", text: $phoneNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                }
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !isRegistering && BiometricAuthManager.shared.isBiometricAvailable {
                    Toggle("Enable \(BiometricAuthManager.shared.biometricType)", isOn: $useBiometrics)
                        .padding(.vertical, 5)
                }
                
                Button(action: {
                    Task {
                        await isRegistering ? register() : login()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(isRegistering ? "Register" : "Login")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(Color.blue)
                .cornerRadius(10)
                .disabled(isLoading)
                
                if !isRegistering && BiometricAuthManager.shared.isBiometricAvailable && !lastEmail.isEmpty {
                    Button(action: {
                        showBiometricAuth = true
                    }) {
                        HStack {
                            Image(systemName: "faceid")
                            Text("Login with \(BiometricAuthManager.shared.biometricType)")
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.top, 5)
                }
                
                Button(action: {
                    isRegistering.toggle()
                }) {
                    Text(isRegistering ? "Already have an account? Login" : "Don't have an account? Register")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .sheet(isPresented: $showBiometricAuth) {
                FaceIDView(isAuthenticated: $isAuthenticated)
            }
            .onChange(of: isAuthenticated) { newValue in
                if newValue {
                    email = lastEmail
                    Task {
                        await biometricLogin()
                    }
                }
            }
        }
    }
    
    // Handles the main login flow using email and password
    // Validates credentials and updates authentication state
    private func login() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await NetworkService.shared.login(email: email, password: password)
            await MainActor.run {
                userId = response.userId
                NetworkService.shared.updateAuthToken(response.accessToken)
                UserDefaults.standard.set(response.refreshToken, forKey: "refreshToken")
                if useBiometrics {
                    lastEmail = email
                }
                isLoggedIn = true
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
    
    // Authenticates user using device biometrics (Face ID/Touch ID)
    // Falls back to password authentication if biometrics unavailable
    private func biometricLogin() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await NetworkService.shared.login(email: email, password: "")
            await MainActor.run {
                userId = response.userId
                NetworkService.shared.updateAuthToken(response.accessToken)
                UserDefaults.standard.set(response.refreshToken, forKey: "refreshToken")
                isLoggedIn = true
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
    
    // Creates a new user account with provided information
    // Validates input and handles any registration errors
    private func register() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await NetworkService.shared.register(
                email: email,
                password: password,
                fullName: fullName,
                phoneNumber: phoneNumber
            )
            await MainActor.run {
                userId = response.userId
                NetworkService.shared.updateAuthToken(response.accessToken)
                UserDefaults.standard.set(response.refreshToken, forKey: "refreshToken")
                isLoggedIn = true
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

struct FaceIDView: View {
    @Binding var isAuthenticated: Bool
    @Environment(\.dismiss) var dismiss
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Authenticate")
                .font(.system(size: 24, weight: .semibold))
                .padding(.top, 50)
            
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 200, height: 200)
                
                VStack(spacing: 20) {
                    Image(systemName: "faceid")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                }
            }
            
            Text("Use \(BiometricAuthManager.shared.biometricType) to quickly\nand securely access\nCommunityAlert")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            Button(action: {
                authenticate()
            }) {
                Text("Authenticate with \(BiometricAuthManager.shared.biometricType)")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Button(action: {
                dismiss()
            }) {
                Text("Cancel")
                    .foregroundColor(.blue)
            }
            .padding(.top)
        }
        .padding()
        .alert("Authentication Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .onAppear {
            authenticate()
        }
    }
    
    // Initiates the biometric authentication process
    // Sets up the authentication context and handles user interaction
    private func authenticate() {
        Task {
            do {
                let success = try await BiometricAuthManager.shared.authenticateUser()
                if success {
                    isAuthenticated = true
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    LoginView()
} 