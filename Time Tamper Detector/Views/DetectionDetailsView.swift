//
//  DetectionDetailsView.swift
//  Time Tamper Detector
//
//  Created by Manoj Gadamsetty on 18/07/25.
//

import SwiftUI

struct DetectionDetailsView: View {
    let result: TimeTamperResult?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if let result = result {
                        // Status Header
                        statusHeader(result: result)
                        
                        // Time Information
                        timeInformationCard(result: result)
                        
                        // Detection Details
                        detectionDetailsCard(result: result)
                        
                        // System Information
                        systemInformationCard(result: result)
                    } else {
                        emptyStateView
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .navigationTitle("Detection Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
    
    // MARK: - Status Header
    
    private func statusHeader(result: TimeTamperResult) -> some View {
        MaterialCard(backgroundColor: result.isTampered ? Color.red.opacity(0.1) : Color.green.opacity(0.1)) {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: result.isTampered ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
                        .font(.largeTitle)
                        .foregroundColor(result.isTampered ? .red : .green)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.isTampered ? "Time Tampering Detected" : "Time Integrity Verified")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(result.isTampered ? .red : .green)
                        
                        Text(confidenceText(result.confidenceLevel))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                Text(result.message)
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
        }
    }
    
    // MARK: - Time Information Card
    
    private func timeInformationCard(result: TimeTamperResult) -> some View {
        MaterialCard {
            VStack(spacing: 16) {
                HStack {
                    Text("Time Information")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    InfoRow(
                        icon: "iphone",
                        title: "Device Time",
                        value: formatDate(result.deviceTime)
                    )
                    
                    if let trustedTime = result.trustedTime {
                        InfoRow(
                            icon: "network",
                            title: "Trusted Time",
                            value: formatDate(trustedTime)
                        )
                        
                        let timeDifference = result.deviceTime.timeIntervalSince(trustedTime)
                        InfoRow(
                            icon: "clock.arrow.circlepath",
                            title: "Time Difference",
                            value: formatTimeDifference(timeDifference),
                            valueColor: abs(timeDifference) > 60 ? .red : .green
                        )
                    }
                    
                    if let bootTime = result.bootTime {
                        InfoRow(
                            icon: "power",
                            title: "System Boot Time",
                            value: formatDate(bootTime)
                        )
                        
                        let uptime = result.deviceTime.timeIntervalSince(bootTime)
                        InfoRow(
                            icon: "timer",
                            title: "System Uptime",
                            value: formatUptime(uptime)
                        )
                    }
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Detection Details Card
    
    private func detectionDetailsCard(result: TimeTamperResult) -> some View {
        MaterialCard {
            VStack(spacing: 16) {
                HStack {
                    Text("Detection Details")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    InfoRow(
                        icon: "magnifyingglass",
                        title: "Detection Method",
                        value: detectionMethodText(result.detectionMethod)
                    )
                    
                    InfoRow(
                        icon: "speedometer",
                        title: "Confidence Level",
                        value: confidenceText(result.confidenceLevel),
                        valueColor: confidenceColor(result.confidenceLevel)
                    )
                    
                    InfoRow(
                        icon: "calendar",
                        title: "Scan Time",
                        value: formatDateTime(result.deviceTime)
                    )
                    
                    InfoRow(
                        icon: result.isTampered ? "xmark.circle" : "checkmark.circle",
                        title: "Status",
                        value: result.isTampered ? "Tampered" : "Verified",
                        valueColor: result.isTampered ? .red : .green
                    )
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - System Information Card
    
    private func systemInformationCard(result: TimeTamperResult) -> some View {
        MaterialCard {
            VStack(spacing: 16) {
                HStack {
                    Text("System Information")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    InfoRow(
                        icon: "gear",
                        title: "Device Model",
                        value: UIDevice.current.model
                    )
                    
                    InfoRow(
                        icon: "square.stack.3d.up",
                        title: "iOS Version",
                        value: UIDevice.current.systemVersion
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
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Detection Data")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("Run a scan to see detailed detection information")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatTimeDifference(_ interval: TimeInterval) -> String {
        let absInterval = abs(interval)
        let sign = interval >= 0 ? "+" : "-"
        
        if absInterval < 60 {
            return "\(sign)\(Int(absInterval))s"
        } else if absInterval < 3600 {
            let minutes = Int(absInterval / 60)
            let seconds = Int(absInterval.truncatingRemainder(dividingBy: 60))
            return "\(sign)\(minutes)m \(seconds)s"
        } else {
            let hours = Int(absInterval / 3600)
            let minutes = Int((absInterval.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(sign)\(hours)h \(minutes)m"
        }
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
    
    private func detectionMethodText(_ method: TimeTamperResult.DetectionMethod) -> String {
        switch method {
        case .networkSync:
            return "Network Synchronization"
        case .storedReference:
            return "Stored Reference"
        case .bootTimeAnalysis:
            return "Boot Time Analysis"
        case .combined:
            return "Combined Analysis"
        }
    }
    
    private func confidenceText(_ confidence: TimeTamperResult.ConfidenceLevel) -> String {
        switch confidence {
        case .high:
            return "High Confidence"
        case .medium:
            return "Medium Confidence"
        case .low:
            return "Low Confidence"
        }
    }
    
    private func confidenceColor(_ confidence: TimeTamperResult.ConfidenceLevel) -> Color {
        switch confidence {
        case .high:
            return .green
        case .medium:
            return .orange
        case .low:
            return .red
        }
    }
}
