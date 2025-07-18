//
//  TimeTamperDetector.swift
//  Time Tamper Detector
//
//  Created by Manoj Gadamsetty on 18/07/25.
//

import Foundation
import Network
import UIKit

// MARK: - Time Tamper Detection Service

protocol TimeTamperDetectorProtocol {
    func detectTimeTampering() async -> TimeTamperResult
    func validateTimeIntegrity() async -> Bool
    func getSystemBootTime() -> Date?
    func getTrustedNetworkTime() async -> NetworkTimeResponse?
}

class TimeTamperDetector: TimeTamperDetectorProtocol {
    private let networkService: NetworkTimeServiceProtocol
    private let storageService: TimeReferenceStorageProtocol
    private let systemService: SystemTimeServiceProtocol
    
    init(
        networkService: NetworkTimeServiceProtocol = NetworkTimeService(),
        storageService: TimeReferenceStorageProtocol = TimeReferenceStorage(),
        systemService: SystemTimeServiceProtocol = SystemTimeService()
    ) {
        self.networkService = networkService
        self.storageService = storageService
        self.systemService = systemService
    }
    
    // MARK: - Main Detection Logic
    
    func detectTimeTampering() async -> TimeTamperResult {
        let deviceTime = Date()
        let bootTime = getSystemBootTime()
        
        // Try network-based detection first
        if let networkTime = await getTrustedNetworkTime() {
            let result = analyzeNetworkTimeComparison(
                deviceTime: deviceTime,
                networkTime: networkTime,
                bootTime: bootTime
            )
            
            // Store this as a new trusted reference if it's reliable
            if networkTime.isReliable && !result.isTampered {
                await storeNewTrustedReference(deviceTime: deviceTime, bootTime: bootTime)
            }
            
            return result
        }
        
        // Fallback to stored reference if network is unavailable
        if let storedReference = await storageService.getLatestTrustedReference() {
            return analyzeStoredReferenceComparison(
                deviceTime: deviceTime,
                storedReference: storedReference,
                bootTime: bootTime
            )
        }
        
        // Fallback to boot time analysis only
        return analyzeBootTimeOnly(deviceTime: deviceTime, bootTime: bootTime)
    }
    
    func validateTimeIntegrity() async -> Bool {
        let result = await detectTimeTampering()
        return !result.isTampered || result.confidenceLevel == .low
    }
    
    // MARK: - System Boot Time
    
    func getSystemBootTime() -> Date? {
        return systemService.getBootTime()
    }
    
    // MARK: - Network Time Service
    
    func getTrustedNetworkTime() async -> NetworkTimeResponse? {
        return await networkService.fetchTrustedTime()
    }
    
    // MARK: - Private Analysis Methods
    
    private func analyzeNetworkTimeComparison(
        deviceTime: Date,
        networkTime: NetworkTimeResponse,
        bootTime: Date?
    ) -> TimeTamperResult {
        let timeDifference = abs(deviceTime.timeIntervalSince(networkTime.serverTime))
        let isTampered = timeDifference > TimeTamperConfig.maxAllowedTimeDrift
        
        let confidenceLevel: TimeTamperResult.ConfidenceLevel = {
            if networkTime.isReliable && networkTime.responseTime < 2.0 {
                return .high
            } else if networkTime.responseTime < 5.0 {
                return .medium
            } else {
                return .low
            }
        }()
        
        let message = generateMessage(
            isTampered: isTampered,
            timeDifference: timeDifference,
            method: .networkSync,
            confidence: confidenceLevel
        )
        
        return TimeTamperResult(
            isTampered: isTampered,
            deviceTime: deviceTime,
            trustedTime: networkTime.serverTime,
            bootTime: bootTime,
            detectionMethod: .networkSync,
            confidenceLevel: confidenceLevel,
            message: message
        )
    }
    
    private func analyzeStoredReferenceComparison(
        deviceTime: Date,
        storedReference: TrustedTimeReference,
        bootTime: Date?
    ) -> TimeTamperResult {
        guard storedReference.isValid else {
            return createLowConfidenceResult(
                deviceTime: deviceTime,
                bootTime: bootTime,
                message: "Stored reference is invalid"
            )
        }
        
        // Enhanced iOS-specific validation using device startup reference
        if let systemService = systemService as? SystemTimeService,
           let currentStartupRef = systemService.getDeviceStartupReference(),
           let storedStartupRef = createStoredStartupReference(from: storedReference) {
            
            let validationResult = systemService.validateUptimeConsistency(previousReference: storedStartupRef)
            
            if validationResult.deviceRebooted {
                return createLowConfidenceResult(
                    deviceTime: deviceTime,
                    bootTime: bootTime,
                    message: "Device rebooted since last reference"
                )
            }
            
            if !validationResult.isValid {
                return TimeTamperResult(
                    isTampered: true,
                    deviceTime: deviceTime,
                    trustedTime: nil,
                    bootTime: bootTime,
                    detectionMethod: .storedReference,
                    confidenceLevel: .high,
                    message: "Uptime inconsistency detected: \(validationResult.reason)"
                )
            }
        }
        
        // Traditional time-based validation
        let expectedCurrentTime = storedReference.timestamp.addingTimeInterval(storedReference.age)
        let timeDifference = abs(deviceTime.timeIntervalSince(expectedCurrentTime))
        let isTampered = timeDifference > TimeTamperConfig.maxAllowedTimeDrift
        
        let confidenceLevel: TimeTamperResult.ConfidenceLevel = {
            if storedReference.age < 3600 { // Less than 1 hour old
                return .high
            } else if storedReference.age < 86400 { // Less than 24 hours old
                return .medium
            } else {
                return .low
            }
        }()
        
        let message = generateMessage(
            isTampered: isTampered,
            timeDifference: timeDifference,
            method: .storedReference,
            confidence: confidenceLevel
        )
        
        return TimeTamperResult(
            isTampered: isTampered,
            deviceTime: deviceTime,
            trustedTime: expectedCurrentTime,
            bootTime: bootTime,
            detectionMethod: .storedReference,
            confidenceLevel: confidenceLevel,
            message: message
        )
    }
    
    private func analyzeBootTimeOnly(
        deviceTime: Date,
        bootTime: Date?
    ) -> TimeTamperResult {
        return createLowConfidenceResult(
            deviceTime: deviceTime,
            bootTime: bootTime,
            message: "No network or stored reference available"
        )
    }
    
    private func createLowConfidenceResult(
        deviceTime: Date,
        bootTime: Date?,
        message: String
    ) -> TimeTamperResult {
        return TimeTamperResult(
            isTampered: false,
            deviceTime: deviceTime,
            trustedTime: nil,
            bootTime: bootTime,
            detectionMethod: .bootTimeAnalysis,
            confidenceLevel: .low,
            message: message
        )
    }
    
    private func generateMessage(
        isTampered: Bool,
        timeDifference: TimeInterval,
        method: TimeTamperResult.DetectionMethod,
        confidence: TimeTamperResult.ConfidenceLevel
    ) -> String {
        if isTampered {
            let minutes = Int(timeDifference / 60)
            return "Time tampering detected! Device time differs by \(minutes) minutes."
        } else {
            return "Time integrity verified. System time appears accurate."
        }
    }
    
    private func storeNewTrustedReference(deviceTime: Date, bootTime: Date?) async {
        let reference = TrustedTimeReference(
            timestamp: deviceTime,
            bootTime: bootTime ?? Date(),
            deviceUptime: systemService.getUptime(),
            createdAt: deviceTime,
            isValid: true
        )
        
        await storageService.storeTrustedReference(reference)
    }
    
    // MARK: - Helper Methods for iOS-specific validation
    
    private func createStoredStartupReference(from reference: TrustedTimeReference) -> DeviceStartupReference? {
        return DeviceStartupReference(
            estimatedBootTime: reference.bootTime,
            processStartTime: reference.createdAt,
            systemUptime: reference.deviceUptime,
            processUptime: 0, // Not stored in legacy reference
            deviceModel: UIDevice.current.model,
            systemVersion: UIDevice.current.systemVersion,
            timestamp: reference.createdAt
        )
    }
}
