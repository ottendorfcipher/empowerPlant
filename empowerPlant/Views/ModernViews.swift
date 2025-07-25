//
//  ModernViews.swift
//  empowerPlant
//
//  Enhanced with modern iOS design system
//

import SwiftUI
import Charts

// MARK: - Profile and Notification Components

struct ProfileAvatarView: View {
    var body: some View {
        Circle()
            .fill(LinearGradient(
                colors: [.green, .mint],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(width: 32, height: 32)
            .overlay(
                Text("NW")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            )
    }
}

struct NotificationBadgeView: View {
    let count: Int
    
    var body: some View {
        ZStack {
            Image(systemName: "bell.fill")
                .font(.title3)
                .foregroundColor(.primary)
            
            if count > 0 {
                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(minWidth: 16, minHeight: 16)
                    .background(Color.red)
                    .clipShape(Circle())
                    .offset(x: 8, y: -8)
            }
        }
    }
}

// MARK: - Analytics View

struct AnalyticsView: View {
    @State private var selectedMetric = "Growth"
    @State private var selectedTimeRange = "Week"
    
    private let metrics = ["Growth", "Water Usage", "Temperature", "Humidity"]
    private let timeRanges = ["Day", "Week", "Month", "Year"]
    
    private let growthData = [
        (day: "Mon", value: 12.0),
        (day: "Tue", value: 15.0),
        (day: "Wed", value: 18.0),
        (day: "Thu", value: 22.0),
        (day: "Fri", value: 19.0),
        (day: "Sat", value: 25.0),
        (day: "Sun", value: 28.0)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Metric Selection
                HStack {
                    Text("Analytics")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.horizontal)
                
                // Time Range Picker
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(timeRanges, id: \.self) { range in
                        Text(range).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Main Chart
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Plant Growth Trends")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        Menu {
                            ForEach(metrics, id: \.self) { metric in
                                Button(metric) {
                                    selectedMetric = metric
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedMetric)
                                Image(systemName: "chevron.down")
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                    }
                    
                    Chart(growthData, id: \.day) { item in
                        LineMark(
                            x: .value("Day", item.day),
                            y: .value("Growth", item.value)
                        )
                        .foregroundStyle(.green)
                        
                        AreaMark(
                            x: .value("Day", item.day),
                            y: .value("Growth", item.value)
                        )
                        .foregroundStyle(.green.opacity(0.1))
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartXAxis {
                        AxisMarks(position: .bottom)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Insights Cards
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    InsightCard(
                        title: "Avg Growth",
                        value: "19.4cm",
                        change: "+12%",
                        trend: .up,
                        icon: "chart.line.uptrend.xyaxis"
                    )
                    
                    InsightCard(
                        title: "Water Efficiency",
                        value: "94%",
                        change: "+3%",
                        trend: .up,
                        icon: "drop.circle"
                    )
                    
                    InsightCard(
                        title: "Yield Prediction",
                        value: "125kg",
                        change: "-2%",
                        trend: .down,
                        icon: "chart.bar.fill"
                    )
                    
                    InsightCard(
                        title: "Health Score",
                        value: "87%",
                        change: "+5%",
                        trend: .up,
                        icon: "heart.circle.fill"
                    )
                }
                .padding(.horizontal)
                
                // AI Recommendations
                VStack(alignment: .leading, spacing: 16) {
                    Text("AI Recommendations")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        RecommendationCard(
                            icon: "drop.fill",
                            title: "Optimize Irrigation",
                            description: "Reduce water usage by 15% in Zone A without affecting growth",
                            priority: .medium,
                            action: "Apply"
                        )
                        
                        RecommendationCard(
                            icon: "thermometer",
                            title: "Temperature Alert",
                            description: "Greenhouse B temperature will exceed optimal range in 2 hours",
                            priority: .high,
                            action: "Adjust"
                        )
                        
                        RecommendationCard(
                            icon: "leaf.circle",
                            title: "Harvest Timing",
                            description: "Tomatoes in Section C ready for harvest in 3-4 days",
                            priority: .low,
                            action: "Schedule"
                        )
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - More View

struct MoreView: View {
    @State private var showingSettings = false
    @State private var showingHelp = false
    @State private var showingAbout = false
    
    var body: some View {
        List {
            Section {
                NavigationLink(destination: IrrigationManagementView()) {
                    MenuRowView(
                        icon: "drop.circle.fill",
                        title: "Irrigation Management",
                        subtitle: "Control water systems",
                        color: .blue
                    )
                }
                
                NavigationLink(destination: FertilizerManagementView()) {
                    MenuRowView(
                        icon: "leaf.arrow.triangle.circlepath",
                        title: "Fertilizer Management",
                        subtitle: "Nutrient scheduling",
                        color: .green
                    )
                }
                
                NavigationLink(destination: PestManagementView()) {
                    MenuRowView(
                        icon: "ant.circle.fill",
                        title: "Pest Management",
                        subtitle: "Monitor & control pests",
                        color: .orange
                    )
                }
                
                NavigationLink(destination: SoilAnalysisView()) {
                    MenuRowView(
                        icon: "globe.americas.fill",
                        title: "Soil Analysis",
                        subtitle: "Soil health metrics",
                        color: .brown
                    )
                }
            } header: {
                Text("Management")
            }
            
            Section {
                NavigationLink(destination: EnvironmentalDataView()) {
                    MenuRowView(
                        icon: "cloud.sun.fill",
                        title: "Environmental Data",
                        subtitle: "Climate monitoring",
                        color: .cyan
                    )
                }
                
                NavigationLink(destination: WaterDataView()) {
                    MenuRowView(
                        icon: "drop.degreesign.fill",
                        title: "Water Quality",
                        subtitle: "pH, TDS, temperature",
                        color: .blue
                    )
                }
                
                NavigationLink(destination: ComplianceView()) {
                    MenuRowView(
                        icon: "checkmark.seal.fill",
                        title: "Compliance",
                        subtitle: "Regulatory tracking",
                        color: .purple
                    )
                }
            } header: {
                Text("Monitoring")
            }
            
            Section {
                Button(action: { showingSettings = true }) {
                    MenuRowView(
                        icon: "gear",
                        title: "Settings",
                        subtitle: "App preferences",
                        color: .gray
                    )
                }
                
                Button(action: { showingHelp = true }) {
                    MenuRowView(
                        icon: "questionmark.circle",
                        title: "Help & Support",
                        subtitle: "Get assistance",
                        color: .indigo
                    )
                }
                
                Button(action: { showingAbout = true }) {
                    MenuRowView(
                        icon: "info.circle",
                        title: "About",
                        subtitle: "App information",
                        color: .secondary
                    )
                }
            } header: {
                Text("Support")
            }
        }
        .navigationTitle("More")
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
}

// MARK: - Supporting Views

struct InsightCard: View {
    let title: String
    let value: String
    let change: String
    let trend: TrendDirection
    let icon: String
    
    enum TrendDirection {
        case up, down, neutral
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
        
        var iconName: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                Spacer()
                HStack(spacing: 2) {
                    Image(systemName: trend.iconName)
                        .font(.caption)
                    Text(change)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(trend.color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

struct RecommendationCard: View {
    let icon: String
    let title: String
    let description: String
    let priority: Priority
    let action: String
    
    enum Priority {
        case high, medium, low
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .blue
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(priority.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: {}) {
                Text(action)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(priority.color)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MenuRowView: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Notification and Profile Views

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let notifications = [
        NotificationItem(
            icon: "exclamationmark.triangle.fill",
            title: "Low Soil Moisture",
            description: "Zone A sensors show moisture below 30%",
            time: "5 min ago",
            priority: .high
        ),
        NotificationItem(
            icon: "thermometer.sun.fill",
            title: "Temperature Alert",
            description: "Greenhouse B exceeding optimal range",
            time: "1 hour ago",
            priority: .medium
        ),
        NotificationItem(
            icon: "checkmark.circle.fill",
            title: "Irrigation Complete",
            description: "Automatic watering cycle finished",
            time: "2 hours ago",
            priority: .low
        )
    ]
    
    var body: some View {
        NavigationView {
            List(notifications, id: \.title) { notification in
                NotificationRowView(notification: notification)
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        ProfileAvatarView()
                            .scaleEffect(1.5)
                        
                        VStack(alignment: .leading) {
                            Text("Nicholas Weiner")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Farm Manager")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Account") {
                    Label("Edit Profile", systemImage: "person.circle")
                    Label("Preferences", systemImage: "slider.horizontal.3")
                    Label("Notifications", systemImage: "bell")
                }
                
                Section("Farm Management") {
                    Label("My Farms", systemImage: "building.2")
                    Label("Team Access", systemImage: "person.2")
                    Label("Data Export", systemImage: "square.and.arrow.up")
                }
                
                Section("Support") {
                    Label("Help Center", systemImage: "questionmark.circle")
                    Label("Contact Support", systemImage: "envelope")
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
                
                Section {
                    Button("Sign Out") {
                        // Handle sign out
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct NotificationItem {
    let icon: String
    let title: String
    let description: String
    let time: String
    let priority: RecommendationCard.Priority
}

struct NotificationRowView: View {
    let notification: NotificationItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notification.icon)
                .font(.title2)
                .foregroundColor(notification.priority.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(notification.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(notification.time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
