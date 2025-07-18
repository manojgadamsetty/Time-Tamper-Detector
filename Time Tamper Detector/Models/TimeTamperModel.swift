//
//  TimeTamperModel.swift
//  Time Tamper Detector
//
//  Created by Manoj Gadamsetty on 18/07/25.
//

import Foundation

// MARK: - Time Tamper Detection Models

struct TimeTamperResult {
    let isTampered: Bool
    let deviceTime: Date
    let trustedTime: Date?
    let bootTime: Date?
    let detectionMethod: DetectionMethod
    let confidenceLevel: ConfidenceLevel
    let message: String
    
    enum DetectionMethod {
        case networkSync
        case storedReference
        case bootTimeAnalysis
        case combined
    }
    
    enum ConfidenceLevel {
        case high
        case medium
        case low
    }
}

struct TrustedTimeReference {
    let timestamp: Date
    let bootTime: Date
    let deviceUptime: TimeInterval
    let createdAt: Date
    let isValid: Bool
    
    var age: TimeInterval {
        Date().timeIntervalSince(createdAt)
    }
}

struct NetworkTimeResponse {
    let serverTime: Date
    let responseTime: TimeInterval
    let isReliable: Bool
}

// MARK: - Configuration

struct TimeTamperConfig {
    static let maxAllowedTimeDrift: TimeInterval = 300 // 5 minutes
    static let referenceValidityDuration: TimeInterval = 86400 // 24 hours
    static let networkTimeoutDuration: TimeInterval = 10 // 10 seconds
    static let trustedTimeServers = [
        "time.apple.com",
        "time.google.com",
        "pool.ntp.org",
        "time.cloudflare.com"
    ]
}
