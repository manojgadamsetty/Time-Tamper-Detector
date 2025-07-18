//
//  MockServices.swift
//  Time Tamper DetectorTests
//
//  Created by Manoj Gadamsetty on 18/07/25.
//

import Foundation
@testable import Time_Tamper_Detector

// MARK: - Mock Network Time Service

class MockNetworkTimeService: NetworkTimeServiceProtocol {
    var mockNetworkTime: NetworkTimeResponse?
    var mockIsNetworkAvailable: Bool = true
    
    func fetchTrustedTime() async -> NetworkTimeResponse? {
        return mockNetworkTime
    }
    
    func isNetworkAvailable() -> Bool {
        return mockIsNetworkAvailable
    }
}

// MARK: - Mock Time Reference Storage

class MockTimeReferenceStorage: TimeReferenceStorageProtocol {
    var mockTrustedReference: TrustedTimeReference?
    var mockAllReferences: [TrustedTimeReference] = []
    var storedReferences: [TrustedTimeReference] = []
    
    func storeTrustedReference(_ reference: TrustedTimeReference) async {
        storedReferences.append(reference)
        mockTrustedReference = reference
    }
    
    func getLatestTrustedReference() async -> TrustedTimeReference? {
        return mockTrustedReference
    }
    
    func clearStoredReferences() async {
        storedReferences.removeAll()
        mockTrustedReference = nil
        mockAllReferences.removeAll()
    }
    
    func getAllTrustedReferences() async -> [TrustedTimeReference] {
        return mockAllReferences.isEmpty ? storedReferences : mockAllReferences
    }
}

// MARK: - Enhanced Mock System Time Service

extension MockSystemTimeService {
    func getDeviceStartupReference() -> DeviceStartupReference? {
        guard let bootTime = mockBootTime else { return nil }
        
        return DeviceStartupReference(
            estimatedBootTime: bootTime,
            processStartTime: Date().addingTimeInterval(-300), // 5 minutes ago
            systemUptime: mockUptime,
            processUptime: 300,
            deviceModel: "iPhone (Test)",
            systemVersion: "17.0",
            timestamp: Date()
        )
    }
}
