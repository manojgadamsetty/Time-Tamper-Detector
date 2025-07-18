//
//  TimeReferenceStorage.swift
//  Time Tamper Detector
//
//  Created by Manoj Gadamsetty on 18/07/25.
//

import Foundation

// MARK: - Time Reference Storage Protocol

protocol TimeReferenceStorageProtocol {
    func storeTrustedReference(_ reference: TrustedTimeReference) async
    func getLatestTrustedReference() async -> TrustedTimeReference?
    func clearStoredReferences() async
    func getAllTrustedReferences() async -> [TrustedTimeReference]
}

// MARK: - Time Reference Storage Implementation

class TimeReferenceStorage: TimeReferenceStorageProtocol {
    private let userDefaults = UserDefaults.standard
    private let storageKey = "TimeTamperTrustedReferences"
    private let maxStoredReferences = 10
    
    func storeTrustedReference(_ reference: TrustedTimeReference) async {
        var references = await getAllTrustedReferences()
        
        // Add new reference at the beginning
        references.insert(reference, at: 0)
        
        // Keep only the most recent references
        if references.count > maxStoredReferences {
            references = Array(references.prefix(maxStoredReferences))
        }
        
        // Remove invalid or expired references
        references = references.filter { ref in
            ref.isValid && ref.age < TimeTamperConfig.referenceValidityDuration
        }
        
        await saveReferences(references)
    }
    
    func getLatestTrustedReference() async -> TrustedTimeReference? {
        let references = await getAllTrustedReferences()
        return references.first { ref in
            ref.isValid && ref.age < TimeTamperConfig.referenceValidityDuration
        }
    }
    
    func clearStoredReferences() async {
        userDefaults.removeObject(forKey: storageKey)
    }
    
    func getAllTrustedReferences() async -> [TrustedTimeReference] {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return []
        }
        
        do {
            let references = try JSONDecoder().decode([TrustedTimeReferenceData].self, from: data)
            return references.compactMap { $0.toTrustedTimeReference() }
        } catch {
            print("Error decoding trusted references: \(error)")
            return []
        }
    }
    
    // MARK: - Private Methods
    
    private func saveReferences(_ references: [TrustedTimeReference]) async {
        let dataObjects = references.map { TrustedTimeReferenceData(from: $0) }
        
        do {
            let data = try JSONEncoder().encode(dataObjects)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            print("Error encoding trusted references: \(error)")
        }
    }
}

// MARK: - Data Transfer Objects

private struct TrustedTimeReferenceData: Codable {
    let timestamp: Double
    let bootTime: Double
    let deviceUptime: TimeInterval
    let createdAt: Double
    let isValid: Bool
    
    init(from reference: TrustedTimeReference) {
        self.timestamp = reference.timestamp.timeIntervalSince1970
        self.bootTime = reference.bootTime.timeIntervalSince1970
        self.deviceUptime = reference.deviceUptime
        self.createdAt = reference.createdAt.timeIntervalSince1970
        self.isValid = reference.isValid
    }
    
    func toTrustedTimeReference() -> TrustedTimeReference {
        return TrustedTimeReference(
            timestamp: Date(timeIntervalSince1970: timestamp),
            bootTime: Date(timeIntervalSince1970: bootTime),
            deviceUptime: deviceUptime,
            createdAt: Date(timeIntervalSince1970: createdAt),
            isValid: isValid
        )
    }
}
