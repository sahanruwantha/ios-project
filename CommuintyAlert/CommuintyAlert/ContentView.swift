//
//  ContentView.swift
//  CommuintyAlert
//
//  Created by user278242 on 4/21/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    
    var body: some View {
        Group {
            if isLoggedIn {
                TabView {
                    HomeView()
                        .tabItem {
                            Label("Home", systemImage: "map.fill")
                        }
                    
                    ReportView()
                        .tabItem {
                            Label("Report", systemImage: "plus.circle.fill")
                        }
                    
                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.fill")
                        }
                }
            } else {
                LoginView()
            }
        }
    }
}

struct SplashScreenView: View {
    @Binding var isActive: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("CommunityAlert")
                .font(.system(size: 28, weight: .semibold))
            
            Text("Stay informed about local\ncommunity alerts and\nemergency notifications")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.top, 20)
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isActive = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
