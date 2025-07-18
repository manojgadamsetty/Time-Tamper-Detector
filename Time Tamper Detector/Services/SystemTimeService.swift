//
//  SystemTimeService.swift
//  Time Tamper Detector
//
//  Created by Manoj Gadamsetty on 18/07/25.
//

import Foundation
import UIKit

// MARK: - System Time Service Protocol

protocol SystemTimeServiceProtocol {
    func getBootTime() -> Date?
    func getUptime() -> TimeInterval
    func getSystemInfo() -> SystemInfo
    func getDeviceStartupReference() -> DeviceStartupReference?
}

// MARK: - System Info Model

struct SystemInfo {
    let bootTime: Date?
    let uptime: TimeInterval
    let currentTime: Date
    let timeZone: TimeZone
    let locale: Locale
    let deviceModel: String
    let systemVersion: String
    let processUptime: TimeInterval
}

// MARK: - Device Startup Reference

struct DeviceStartupReference {
    let estimatedBootTime: Date
    let processStartTime: Date
    let systemUptime: TimeInterval
    let processUptime: TimeInterval
    let deviceModel: String
    let systemVersion: String
    let timestamp: Date
    
    var isValid: Bool {
        // Validate that the reference is internally consistent
        let timeDifference = abs(estimatedBootTime.timeIntervalSince(processStartTime.addingTimeInterval(-processUptime)))
        return timeDifference < 60 // Allow 1 minute tolerance
    }
}

// MARK: - System Time Service Implementation

class SystemTimeService: SystemTimeServiceProtocol {
    private let processStartTime: Date = Date()
    
    func getBootTime() -> Date? {
        // iOS-specific approach: Calculate boot time from system uptime
        let uptime = getUptime()
        let currentTime = Date()
        let estimatedBootTime = currentTime.addingTimeInterval(-uptime)
        
        // Validate that the calculated boot time is reasonable
        let thirtyDaysAgo = currentTime.addingTimeInterval(-30 * 24 * 60 * 60)
        let oneMinuteAgo = currentTime.addingTimeInterval(-60)
        
        guard estimatedBootTime > thirtyDaysAgo && estimatedBootTime < oneMinuteAgo else {
            print("Calculated boot time seems unreasonable: \(estimatedBootTime)")
            return nil
        }
        
        return estimatedBootTime
    }
    
    func getUptime() -> TimeInterval {
        // Use ProcessInfo.systemUptime - most reliable on iOS
        return ProcessInfo.processInfo.systemUptime
    }
    
    func getSystemInfo() -> SystemInfo {
        return SystemInfo(
            bootTime: getBootTime(),
            uptime: getUptime(),
            currentTime: Date(),
            timeZone: TimeZone.current,
            locale: Locale.current,
            deviceModel: UIDevice.current.model,
            systemVersion: UIDevice.current.systemVersion,
            processUptime: Date().timeIntervalSince(processStartTime)
        )
    }
    
    func getDeviceStartupReference() -> DeviceStartupReference? {
        guard let bootTime = getBootTime() else {
            return nil
        }
        
        return DeviceStartupReference(
            estimatedBootTime: bootTime,
            processStartTime: processStartTime,
            systemUptime: getUptime(),
            processUptime: Date().timeIntervalSince(processStartTime),
            deviceModel: UIDevice.current.model,
            systemVersion: UIDevice.current.systemVersion,
            timestamp: Date()
        )
    }
}

// MARK: - Enhanced iOS-Specific Methods

extension SystemTimeService {
    
    /// Get multiple uptime measurements for cross-validation
    func getUptimeMetrics() -> UptimeMetrics {
        let systemUptime = ProcessInfo.processInfo.systemUptime
        let processUptime = Date().timeIntervalSince(processStartTime)
        
        // Additional iOS-specific timing information
        let thermalState = ProcessInfo.processInfo.thermalState
        let isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        
        return UptimeMetrics(
            systemUptime: systemUptime,
            processUptime: processUptime,
            thermalState: thermalState,
            isLowPowerModeEnabled: isLowPowerModeEnabled,
            timestamp: Date()
        )
    }
    
    /// Detect potential time manipulation by analyzing uptime consistency
    func validateUptimeConsistency(previousReference: DeviceStartupReference?) -> UptimeValidationResult {
        guard let previous = previousReference,
              let currentBootTime = getBootTime() else {
            return UptimeValidationResult(isValid: false, reason: "Insufficient data for validation")
        }
        
        // Check if device was rebooted (boot time changed)
        let bootTimeDifference = abs(currentBootTime.timeIntervalSince(previous.estimatedBootTime))
        
        if bootTimeDifference > 60 { // More than 1 minute difference
            return UptimeValidationResult(
                isValid: true,
                reason: "Device was rebooted since last reference",
                deviceRebooted: true
            )
        }
        
        // Validate uptime progression
        let expectedCurrentUptime = previous.systemUptime + Date().timeIntervalSince(previous.timestamp)
        let actualCurrentUptime = getUptime()
        let uptimeDifference = abs(actualCurrentUptime - expectedCurrentUptime)
        
        // Allow small tolerance for measurement differences
        let isUptimeValid = uptimeDifference < 300 // 5 minutes tolerance
        
        return UptimeValidationResult(
            isValid: isUptimeValid,
            reason: isUptimeValid ? "Uptime progression is consistent" : "Uptime inconsistency detected",
            deviceRebooted: false,
            uptimeDifference: uptimeDifference
        )
    }
}

// MARK: - Supporting Models

struct UptimeMetrics {
    let systemUptime: TimeInterval
    let processUptime: TimeInterval
    let thermalState: ProcessInfo.ThermalState
    let isLowPowerModeEnabled: Bool
    let timestamp: Date
}

struct UptimeValidationResult {
    let isValid: Bool
    let reason: String
    let deviceRebooted: Bool
    let uptimeDifference: TimeInterval?
    
    init(isValid: Bool, reason: String, deviceRebooted: Bool = false, uptimeDifference: TimeInterval? = nil) {
        self.isValid = isValid
        self.reason = reason
        self.deviceRebooted = deviceRebooted
        self.uptimeDifference = uptimeDifference
    }
}

// MARK: - Mock System Time Service for Testing

class MockSystemTimeService: SystemTimeServiceProtocol {
    private var mockBootTime: Date?
    private var mockUptime: TimeInterval
    private var mockDeviceStartupReference: DeviceStartupReference?
    
    init(bootTime: Date? = nil, uptime: TimeInterval = 3600) {
        self.mockBootTime = bootTime
        self.mockUptime = uptime
    }
    
    func getBootTime() -> Date? {
        return mockBootTime
    }
    
    func getUptime() -> TimeInterval {
        return mockUptime
    }
    
    func getSystemInfo() -> SystemInfo {
        return SystemInfo(
            bootTime: mockBootTime,
            uptime: mockUptime,
            currentTime: Date(),
            timeZone: TimeZone.current,
            locale: Locale.current,
            deviceModel: "iPhone (Simulator)",
            systemVersion: "17.0",
            processUptime: 300 // 5 minutes
        )
    }
    
    func getDeviceStartupReference() -> DeviceStartupReference? {
        return mockDeviceStartupReference
    }
    
    // MARK: - Testing Helpers
    
    func setMockBootTime(_ bootTime: Date?) {
        self.mockBootTime = bootTime
    }
    
    func setMockUptime(_ uptime: TimeInterval) {
        self.mockUptime = uptime
    }
    
    func setMockDeviceStartupReference(_ reference: DeviceStartupReference?) {
        self.mockDeviceStartupReference = reference
    }
}
