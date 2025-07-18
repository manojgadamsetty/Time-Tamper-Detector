//
//  TimeTamperMainView.swift
//  Time Tamper Detector
//
//  Created by Manoj Gadamsetty on 18/07/25.
//

import SwiftUI

struct TimeTamperMainView: View {
    @ObservedObject var viewModel: TimeTamperViewModel
    @State private var showDetails = false
    @State private var pulseAnimation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Main Scan Button
                    scanButtonSection
                    
                    // Status Card
                    if viewModel.detectionResult != nil {
                        statusCard
                    }
                    
                    // Quick Stats
                    quickStatsSection
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .navigationTitle("Time Tamper Detector")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .alert("Error", isPresented: $viewModel.showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        MaterialCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "shield.checkered")
                        .font(.title)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Security Status")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Real-time time integrity monitoring")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                HStack {
                    StatusIndicator(
                        status: viewModel.currentStatus,
                        color: viewModel.statusColor
                    )
                    Spacer()
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Scan Button Section
    
    private var scanButtonSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 140, height: 140)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .opacity(pulseAnimation ? 0.5 : 1.0)
                    .animation(
                        viewModel.isScanning ? 
                        Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) : 
                        .default,
                        value: pulseAnimation
                    )
                
                Button(action: {
                    Task {
                        await viewModel.startScan()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 100, height: 100)
                        
                        if viewModel.isScanning {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                        } else {
                            Image(systemName: "play.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(viewModel.isScanning)
                .scaleEffect(viewModel.isScanning ? 0.9 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isScanning)
            }
            .onAppear {
                pulseAnimation = viewModel.isScanning
            }
            .onChange(of: viewModel.isScanning) { isScanning in
                pulseAnimation = isScanning
            }
            
            Text(viewModel.isScanning ? "Scanning..." : "Start Scan")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Status Card
    
    private var statusCard: some View {
        MaterialCard {
            VStack(spacing: 20) {
                HStack {
                    if let result = viewModel.detectionResult {
                        if result.isTampered {
                            AnimatedXMark(size: 50, color: .red)
                        } else {
                            AnimatedCheckmark(size: 50, color: .green)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.currentStatus)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(viewModel.statusColor)
                        
                        Text(viewModel.confidenceText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.detectionMethodText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                if let result = viewModel.detectionResult {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(result.message)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Button("View Details") {
                            showDetails = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                }
            }
            .padding(20)
        }
        .sheet(isPresented: $showDetails) {
            DetectionDetailsView(result: viewModel.detectionResult)
        }
    }
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        MaterialCard {
            VStack(spacing: 16) {
                HStack {
                    Text("Quick Stats")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    statItem(
                        icon: "clock",
                        title: "Total Scans",
                        value: "\(viewModel.scanHistory.count)"
                    )
                    
                    statItem(
                        icon: "exclamationmark.triangle",
                        title: "Threats Found",
                        value: "\(viewModel.scanHistory.filter { $0.isTampered }.count)"
                    )
                    
                    statItem(
                        icon: "checkmark.shield",
                        title: "Clean Scans",
                        value: "\(viewModel.scanHistory.filter { !$0.isTampered }.count)"
                    )
                    
                    statItem(
                        icon: "timer",
                        title: "Last Scan",
                        value: lastScanTime
                    )
                }
            }
            .padding(20)
        }
    }
    
    private func statItem(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var lastScanTime: String {
        guard let lastScan = viewModel.scanHistory.first else {
            return "Never"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastScan.deviceTime, relativeTo: Date())
    }
}
