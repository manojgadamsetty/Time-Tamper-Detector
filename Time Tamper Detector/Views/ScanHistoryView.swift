//
//  ScanHistoryView.swift
//  Time Tamper Detector
//
//  Created by Manoj Gadamsetty on 18/07/25.
//

import SwiftUI

struct ScanHistoryView: View {
    @ObservedObject var viewModel: TimeTamperViewModel
    @State private var showingExportSheet = false
    @State private var exportedData = ""
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.scanHistory.isEmpty {
                    emptyStateView
                } else {
                    historyListView
                }
            }
            .navigationTitle("Scan History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !viewModel.scanHistory.isEmpty {
                        Button("Export") {
                            exportedData = viewModel.exportScanHistory()
                            showingExportSheet = true
                        }
                        
                        Button("Clear") {
                            showingClearAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showingExportSheet) {
                ExportView(data: exportedData)
            }
            .alert("Clear History", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    viewModel.clearHistory()
                }
            } message: {
                Text("Are you sure you want to clear all scan history? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - History List View
    
    private var historyListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.scanHistory.enumerated()), id: \.offset) { index, result in
                    HistoryRowView(result: result, index: index)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Scan History")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Your scan history will appear here after you perform your first security scan.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            MaterialButton(
                title: "Start First Scan",
                style: .primary
            ) {
                Task {
                    await viewModel.startScan()
                }
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - History Row View

struct HistoryRowView: View {
    let result: TimeTamperResult
    let index: Int
    @State private var showingDetails = false
    
    var body: some View {
        MaterialCard {
            VStack(spacing: 12) {
                HStack {
                    // Status Indicator
                    statusIndicator
                    
                    // Main Content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.isTampered ? "Threat Detected" : "System Secure")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(result.isTampered ? .red : .green)
                        
                        Text(formatScanTime(result.deviceTime))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(detectionMethodText(result.detectionMethod))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Confidence Badge
                    confidenceBadge
                }
                
                // Summary Message
                if !result.message.isEmpty {
                    Divider()
                    
                    Text(result.message)
                        .font(.body)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Action Button
                HStack {
                    Spacer()
                    
                    Button("View Details") {
                        showingDetails = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            .padding(16)
        }
        .sheet(isPresented: $showingDetails) {
            DetectionDetailsView(result: result)
        }
    }
    
    private var statusIndicator: some View {
        ZStack {
            Circle()
                .fill(result.isTampered ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                .frame(width: 40, height: 40)
            
            Image(systemName: result.isTampered ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(result.isTampered ? .red : .green)
        }
    }
    
    private var confidenceBadge: some View {
        Text(confidenceText(result.confidenceLevel))
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(confidenceColor(result.confidenceLevel).opacity(0.2))
            .foregroundColor(confidenceColor(result.confidenceLevel))
            .cornerRadius(8)
    }
    
    private func formatScanTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func detectionMethodText(_ method: TimeTamperResult.DetectionMethod) -> String {
        switch method {
        case .networkSync:
            return "Network Sync"
        case .storedReference:
            return "Stored Reference"
        case .bootTimeAnalysis:
            return "Boot Analysis"
        case .combined:
            return "Combined"
        }
    }
    
    private func confidenceText(_ confidence: TimeTamperResult.ConfidenceLevel) -> String {
        switch confidence {
        case .high:
            return "HIGH"
        case .medium:
            return "MED"
        case .low:
            return "LOW"
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

// MARK: - Export View

struct ExportView: View {
    let data: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(data)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: data) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}
