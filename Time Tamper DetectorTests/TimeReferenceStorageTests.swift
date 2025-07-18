//
//  TimeReferenceStorageTests.swift
//  Time Tamper DetectorTests
//
//  Created by Manoj Gadamsetty on 18/07/25.
//

import XCTest
@testable import Time_Tamper_Detector

final class TimeReferenceStorageTests: XCTestCase {
    
    var storage: TimeReferenceStorage!
    
    override func setUpWithError() throws {
        super.setUp()
        storage = TimeReferenceStorage()
        
        // Clear any existing data
        Task {
            await storage.clearStoredReferences()
        }
    }
    
    override func tearDownWithError() throws {
        Task {
            await storage.clearStoredReferences()
        }
        storage = nil
        super.tearDown()
    }
    
    // MARK: - Storage Tests
    
    func testStoreTrustedReference() async throws {
        // Given
        let reference = createTestReference()
        
        // When
        await storage.storeTrustedReference(reference)
        
        // Then
        let storedReference = await storage.getLatestTrustedReference()
        XCTAssertNotNil(storedReference)
        XCTAssertEqual(storedReference?.timestamp.timeIntervalSince1970, 
                      reference.timestamp.timeIntervalSince1970, 
                      accuracy: 1.0)
        XCTAssertEqual(storedReference?.isValid, reference.isValid)
    }
    
    func testGetLatestTrustedReference_NoData() async throws {
        // When
        let reference = await storage.getLatestTrustedReference()
        
        // Then
        XCTAssertNil(reference)
    }
    
    func testGetLatestTrustedReference_WithMultipleReferences() async throws {
        // Given
        let oldReference = createTestReference(timeOffset: -7200) // 2 hours ago
        let newReference = createTestReference(timeOffset: -3600) // 1 hour ago
        
        // When
        await storage.storeTrustedReference(oldReference)
        await storage.storeTrustedReference(newReference)
        
        // Then
        let latestReference = await storage.getLatestTrustedReference()
        XCTAssertNotNil(latestReference)
        // Should return the newer reference
        XCTAssertEqual(latestReference?.timestamp.timeIntervalSince1970,
                      newReference.timestamp.timeIntervalSince1970,
                      accuracy: 1.0)
    }
    
    func testGetAllTrustedReferences() async throws {
        // Given
        let reference1 = createTestReference(timeOffset: -7200)
        let reference2 = createTestReference(timeOffset: -3600)
        let reference3 = createTestReference(timeOffset: -1800)
        
        // When
        await storage.storeTrustedReference(reference1)
        await storage.storeTrustedReference(reference2)
        await storage.storeTrustedReference(reference3)
        
        // Then
        let allReferences = await storage.getAllTrustedReferences()
        XCTAssertEqual(allReferences.count, 3)
    }
    
    func testClearStoredReferences() async throws {
        // Given
        let reference = createTestReference()
        await storage.storeTrustedReference(reference)
        
        // Verify it's stored
        let storedReference = await storage.getLatestTrustedReference()
        XCTAssertNotNil(storedReference)
        
        // When
        await storage.clearStoredReferences()
        
        // Then
        let clearedReference = await storage.getLatestTrustedReference()
        XCTAssertNil(clearedReference)
        
        let allReferences = await storage.getAllTrustedReferences()
        XCTAssertTrue(allReferences.isEmpty)
    }
    
    func testStoreTrustedReference_MaxLimit() async throws {
        // Given - Store more than the max limit (10)
        for i in 0..<15 {
            let reference = createTestReference(timeOffset: TimeInterval(-i * 3600))
            await storage.storeTrustedReference(reference)
        }
        
        // When
        let allReferences = await storage.getAllTrustedReferences()
        
        // Then - Should not exceed max limit
        XCTAssertLessThanOrEqual(allReferences.count, 10)
    }
    
    func testStoreTrustedReference_ExpiredReferencesRemoved() async throws {
        // Given - Create an expired reference (older than 24 hours)
        let expiredReference = createTestReference(
            timeOffset: -25 * 60 * 60, // 25 hours ago
            createdOffset: -25 * 60 * 60
        )
        let validReference = createTestReference()
        
        // When
        await storage.storeTrustedReference(expiredReference)
        await storage.storeTrustedReference(validReference)
        
        // Then - Expired reference should be filtered out
        let allReferences = await storage.getAllTrustedReferences()
        XCTAssertEqual(allReferences.count, 1)
        XCTAssertEqual(allReferences.first?.timestamp.timeIntervalSince1970,
                      validReference.timestamp.timeIntervalSince1970,
                      accuracy: 1.0)
    }
    
    // MARK: - Data Persistence Tests
    
    func testDataPersistence() async throws {
        // Given
        let reference = createTestReference()
        await storage.storeTrustedReference(reference)
        
        // When - Create a new storage instance (simulating app restart)
        let newStorage = TimeReferenceStorage()
        
        // Then - Data should persist
        let persistedReference = await newStorage.getLatestTrustedReference()
        XCTAssertNotNil(persistedReference)
        XCTAssertEqual(persistedReference?.timestamp.timeIntervalSince1970,
                      reference.timestamp.timeIntervalSince1970,
                      accuracy: 1.0)
    }
    
    // MARK: - Helper Methods
    
    private func createTestReference(
        timeOffset: TimeInterval = 0,
        createdOffset: TimeInterval? = nil
    ) -> TrustedTimeReference {
        let baseTime = Date()
        return TrustedTimeReference(
            timestamp: baseTime.addingTimeInterval(timeOffset),
            bootTime: baseTime.addingTimeInterval(-3600), // 1 hour before
            deviceUptime: 3600,
            createdAt: baseTime.addingTimeInterval(createdOffset ?? timeOffset),
            isValid: true
        )
    }
}

// MARK: - TrustedTimeReference Tests

final class TrustedTimeReferenceTests: XCTestCase {
    
    func testAge_Calculation() {
        // Given
        let createdTime = Date().addingTimeInterval(-3600) // 1 hour ago
        let reference = TrustedTimeReference(
            timestamp: createdTime,
            bootTime: createdTime.addingTimeInterval(-1800),
            deviceUptime: 1800,
            createdAt: createdTime,
            isValid: true
        )
        
        // When
        let age = reference.age
        
        // Then - Age should be approximately 1 hour (3600 seconds)
        XCTAssertEqual(age, 3600, accuracy: 10) // 10 seconds tolerance
    }
    
    func testAge_RecentReference() {
        // Given
        let recentTime = Date()
        let reference = TrustedTimeReference(
            timestamp: recentTime,
            bootTime: recentTime.addingTimeInterval(-3600),
            deviceUptime: 3600,
            createdAt: recentTime,
            isValid: true
        )
        
        // When
        let age = reference.age
        
        // Then - Age should be very small (nearly 0)
        XCTAssertLessThan(age, 1.0)
    }
}
