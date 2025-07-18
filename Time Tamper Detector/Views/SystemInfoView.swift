//
//  SystemInfoView.swift
//  Time Tamper Detector
//
//  Created by Manoj Gadamsetty on 18/07/25.
//

import SwiftUI

struct SystemInfoView: View {
    @ObservedObject var viewModel: TimeTamperViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Device Information
                    deviceInformationCard
                    
                    // Time Information
                    timeInformationCard
                    
                    // System Status
                    systemStatusCard
                    
                    // Boot Information
                    if let systemInfo = viewModel.systemInfo {
                        bootInformationCard(systemInfo: systemInfo)
                    }
                    
                    // Settings & Actions
                    settingsCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle("System Info")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .onAppear {
                viewModel.refreshSystemInfo()
            }
        }
    }
    
    // MARK: - Device Information Card
    
    private var deviceInformationCard: some View {
        MaterialCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "iphone")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("Device Information")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    InfoRow(
                        icon: "devicephone",
                        title: "Device Model",
                        value: UIDevice.current.model
                    )
                    
                    InfoRow(
                        icon: "square.stack.3d.up",
                        title: "iOS Version",
                        value: UIDevice.current.systemVersion
                    )
                    
                    InfoRow(
                        icon: "cpu",
                        title: "System Name",
                        value: UIDevice.current.systemName
                    )
                    
                    InfoRow(
                        icon: "memorychip",
                        title: "Device Name",
                        value: UIDevice.current.name
                    )
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Time Information Card
    
    private var timeInformationCard: some View {
        MaterialCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "clock")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("Time Information")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Refresh") {
                        viewModel.refreshSystemInfo()
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                
                VStack(spacing: 12) {
                    InfoRow(
                        icon: "clock.fill",
                        title: "Current Time",
                        value: formatCurrentTime()
                    )
                    
                    InfoRow(
                        icon: "globe",
                        title: "Time Zone",
                        value: TimeZone.current.identifier
                    )
                    
                    InfoRow(
                        icon: "location",
                        title: "Locale",
                        value: Locale.current.identifier
                    )
                    
                    InfoRow(
                        icon: "calendar",
                        title: "Calendar",
                        value: String(describing: Calendar.current.identifier)
                    )
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - System Status Card
    
    private var systemStatusCard: some View {
        MaterialCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "shield.checkered")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("Security Status")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    InfoRow(
                        icon: "checkmark.shield",
                        title: "Time Integrity",
                        value: viewModel.detectionResult?.isTampered == false ? "Verified" : "Unknown",
                        valueColor: viewModel.detectionResult?.isTampered == false ? .green : .orange
                    )
                    
                    InfoRow(
                        icon: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                        title: "Last Scan",
                        value: lastScanTime
                    )
                    
                    InfoRow(
                        icon: "list.number",
                        title: "Total Scans",
                        value: "\(viewModel.scanHistory.count)"
                    )
                    
                    InfoRow(
                        icon: "exclamationmark.triangle",
                        title: "Threats Found",
                        value: "\(viewModel.scanHistory.filter { $0.isTampered }.count)",
                        valueColor: viewModel.scanHistory.filter { $0.isTampered }.count > 0 ? .red : .green
                    )
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Boot Information Card
    
    private func bootInformationCard(systemInfo: SystemInfo) -> some View {
        MaterialCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "power")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("Boot Information")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    if let bootTime = systemInfo.bootTime {
                        InfoRow(
                            icon: "power.circle",
                            title: "Boot Time",
                            value: formatDate(bootTime)
                        )
                        
                        InfoRow(
                            icon: "timer",
                            title: "System Uptime",
                            value: formatUptime(systemInfo.uptime)
                        )
                    } else {
                        InfoRow(
                            icon: "questionmark.circle",
                            title: "Boot Time",
                            value: "Unavailable",
                            valueColor: .orange
                        )
                    }
                    
                    InfoRow(
                        icon: "speedometer",
                        title: "Process Uptime",
                        value: formatUptime(ProcessInfo.processInfo.systemUptime)
                    )
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Settings Card
    
    private var settingsCard: some View {
        MaterialCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "gear")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("Settings & Actions")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    actionButton(
                        icon: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                        title: "Refresh System Info",
                        action: {
                            viewModel.refreshSystemInfo()
                        }
                    )
                    
                    actionButton(
                        icon: "trash",
                        title: "Clear Scan History",
                        action: {
                            viewModel.clearHistory()
                        },
                        isDestructive: true
                    )
                    
                    actionButton(
                        icon: "square.and.arrow.up",
                        title: "Export System Info",
                        action: {
                            exportSystemInfo()
                        }
                    )
                }
            }
            .padding(20)
        }
    }
    
    private func actionButton(
        icon: String,
        title: String,
        action: @escaping () -> Void,
        isDestructive: Bool = false
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(isDestructive ? .red : .blue)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(isDestructive ? .red : .primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods
    
    private func formatCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: Date())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatUptime(_ interval: TimeInterval) -> String {
        let days = Int(interval / 86400)
        let hours = Int((interval.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var lastScanTime: String {
        guard let lastScan = viewModel.scanHistory.first else {
            return "Never"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastScan.deviceTime, relativeTo: Date())
    }
    
    private func exportSystemInfo() {
        // Implementation for exporting system info
        // This could show a share sheet or save to files
        print("Export system info")
    }
}
