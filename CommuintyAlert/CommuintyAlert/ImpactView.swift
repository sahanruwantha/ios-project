import SwiftUI

struct ImpactView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("Community Impact")
                    .font(.system(size: 24, weight: .semibold))
                    .padding(.top)
                
                // Impact Stats
                VStack(spacing: 20) {
                    // Alerts Reported
                    StatCard(
                        value: "247",
                        label: "Alerts Reported",
                        color: .blue
                    )
                    
                    // Community Engagement
                    StatCard(
                        value: "86%",
                        label: "Community Engagement",
                        color: Color(red: 0.29, green: 0.56, blue: 0.89)
                    )
                    
                    // Critical Incidents
                    StatCard(
                        value: "12",
                        label: "Critical Incidents",
                        color: .red
                    )
                }
                .padding(.horizontal)
                
                // Leaderboard
                VStack(alignment: .leading, spacing: 15) {
                    Text("Top Contributors")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        ContributorRow(name: "Sarah Johnson", rank: 1)
                        ContributorRow(name: "Mike Rodriguez", rank: 2)
                        ContributorRow(name: "Emily Chen", rank: 3)
                        ContributorRow(name: "David Wilson", rank: 4)
                        ContributorRow(name: "Lisa Thompson", rank: 5)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Text(value)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(20)
    }
}

struct ContributorRow: View {
    let name: String
    let rank: Int
    
    var body: some View {
        HStack {
            Text("\(rank).")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(name)
                .font(.system(size: 14))
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 12))
        }
    }
}

#Preview {
    ImpactView()
} 