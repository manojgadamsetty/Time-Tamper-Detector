//
//  TimeTamperViewModel.swift
//  Time Tamper Detector
//
//  Created by Manoj Gadamsetty on 18/07/25.
//

import Foundation
import SwiftUI

// MARK: - Time Tamper View Model

@MainActor
class TimeTamperViewModel: ObservableObject {
    @Published var detectionResult: TimeTamperResult?
    @Published var isScanning: Bool = false
    @Published var scanHistory: [TimeTamperResult] = []
    @Published var systemInfo: SystemInfo?
    @Published var errorMessage: String?
    @Published var showErrorAlert: Bool = false
    
    private let detector: TimeTamperDetectorProtocol
    private let systemService: SystemTimeServiceProtocol
    private let maxHistoryItems = 50
    
    // MARK: - Computed Properties
    
    var currentStatus: String {
        guard let result = detectionResult else {
            return "Ready to scan"
        }
        
        return result.isTampered ? "Time Tampering Detected" : "Time Integrity Verified"
    }
    
    var statusColor: Color {
        guard let result = detectionResult else {
            return .blue
        }
        
        if result.isTampered {
            return .red
        } else {
            switch result.confidenceLevel {
            case .high:
                return .green
            case .medium:
                return .orange
            case .low:
                return .yellow
            }
        }
    }
    
    var confidenceText: String {
        guard let result = detectionResult else {
            return ""
        }
        
        switch result.confidenceLevel {
        case .high:
            return "High Confidence"
        case .medium:
            return "Medium Confidence"
        case .low:
            return "Low Confidence"
        }
    }
    
    var detectionMethodText: String {
        guard let result = detectionResult else {
            return ""
        }
        
        switch result.detectionMethod {
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
    
    // MARK: - Initialization
    
    init(detector: TimeTamperDetectorProtocol = TimeTamperDetector()) {
        self.detector = detector
        self.systemService = SystemTimeService()
        loadScanHistory()
        loadSystemInfo()
    }
    
    // MARK: - Public Methods
    
    func startScan() async {
        isScanning = true
        errorMessage = nil
        showErrorAlert = false
        
        do {
            let result = await detector.detectTimeTampering()
            detectionResult = result
            addToHistory(result)
            await saveScanHistory()
        } catch {
            errorMessage = "Failed to perform time tampering scan: \(error.localizedDescription)"
            showErrorAlert = true
        }
        
        isScanning = false
    }
    
    func refreshSystemInfo() {
        loadSystemInfo()
    }
    
    func clearHistory() {
        scanHistory.removeAll()
        Task {
            await saveScanHistory()
        }
    }
    
    func exportScanHistory() -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let historyData = scanHistory.map { ScanHistoryItem(from: $0) }
            let data = try encoder.encode(historyData)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return "Failed to export scan history: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Private Methods
    
    private func addToHistory(_ result: TimeTamperResult) {
        scanHistory.insert(result, at: 0)
        
        // Keep only the most recent items
        if scanHistory.count > maxHistoryItems {
            scanHistory = Array(scanHistory.prefix(maxHistoryItems))
        }
    }
    
    private func loadSystemInfo() {
        systemInfo = systemService.getSystemInfo()
    }
    
    private func loadScanHistory() {
        guard let data = UserDefaults.standard.data(forKey: "ScanHistory") else {
            return
        }
        
        do {
            let historyItems = try JSONDecoder().decode([ScanHistoryItem].self, from: data)
            scanHistory = historyItems.compactMap { $0.toTimeTamperResult() }
        } catch {
            print("Failed to load scan history: \(error)")
        }
    }
    
    private func saveScanHistory() async {
        let historyData = scanHistory.map { ScanHistoryItem(from: $0) }
        
        do {
            let data = try JSONEncoder().encode(historyData)
            UserDefaults.standard.set(data, forKey: "ScanHistory")
        } catch {
            print("Failed to save scan history: \(error)")
        }
    }
}

// MARK: - Scan History Data Model

private struct ScanHistoryItem: Codable {
    let isTampered: Bool
    let deviceTime: Double
    let trustedTime: Double?
    let bootTime: Double?
    let detectionMethod: String
    let confidenceLevel: String
    let message: String
    
    init(from result: TimeTamperResult) {
        self.isTampered = result.isTampered
        self.deviceTime = result.deviceTime.timeIntervalSince1970
        self.trustedTime = result.trustedTime?.timeIntervalSince1970
        self.bootTime = result.bootTime?.timeIntervalSince1970
        self.detectionMethod = String(describing: result.detectionMethod)
        self.confidenceLevel = String(describing: result.confidenceLevel)
        self.message = result.message
    }
    
    func toTimeTamperResult() -> TimeTamperResult {
        let method: TimeTamperResult.DetectionMethod = {
            switch detectionMethod {
            case "networkSync":
                return .networkSync
            case "storedReference":
                return .storedReference
            case "bootTimeAnalysis":
                return .bootTimeAnalysis
            case "combined":
                return .combined
            default:
                return .bootTimeAnalysis
            }
        }()
        
        let confidence: TimeTamperResult.ConfidenceLevel = {
            switch confidenceLevel {
            case "high":
                return .high
            case "medium":
                return .medium
            case "low":
                return .low
            default:
                return .low
            }
        }()
        
        return TimeTamperResult(
            isTampered: isTampered,
            deviceTime: Date(timeIntervalSince1970: deviceTime),
            trustedTime: trustedTime.map { Date(timeIntervalSince1970: $0) },
            bootTime: bootTime.map { Date(timeIntervalSince1970: $0) },
            detectionMethod: method,
            confidenceLevel: confidence,
            message: message
        )
    }
}
