//
//  Time_Tamper_DetectorTests.swift
//  Time Tamper DetectorTests
//
//  Created by Manoj Gadamsetty on 18/07/25.
//

import XCTest
@testable import Time_Tamper_Detector

final class Time_Tamper_DetectorTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        //
//  Time_Tamper_DetectorTests.swift
//  Time Tamper DetectorTests
//
//  Created by Manoj Gadamsetty on 18/07/25.
//

import XCTest
@testable import Time_Tamper_Detector

final class Time_Tamper_DetectorTests: XCTestCase {
    
    var timeTamperDetector: TimeTamperDetector!
    var mockNetworkService: MockNetworkTimeService!
    var mockStorageService: MockTimeReferenceStorage!
    var mockSystemService: MockSystemTimeService!
    
    override func setUpWithError() throws {
        super.setUp()
        
        mockNetworkService = MockNetworkTimeService()
        mockStorageService = MockTimeReferenceStorage()
        mockSystemService = MockSystemTimeService()
        
        timeTamperDetector = TimeTamperDetector(
            networkService: mockNetworkService,
            storageService: mockStorageService,
            systemService: mockSystemService
        )
    }
    
    override func tearDownWithError() throws {
        timeTamperDetector = nil
        mockNetworkService = nil
        mockStorageService = nil
        mockSystemService = nil
        super.tearDown()
    }
    
    // MARK: - Network Time Detection Tests
    
    func testDetectTimeTampering_WithNetworkTime_NoTampering() async throws {
        // Given
        let currentTime = Date()
        let networkTime = NetworkTimeResponse(
            serverTime: currentTime.addingTimeInterval(30), // 30 seconds difference
            responseTime: 1.0,
            isReliable: true
        )
        mockNetworkService.mockNetworkTime = networkTime
        mockSystemService.setMockBootTime(currentTime.addingTimeInterval(-3600)) // 1 hour ago
        
        // When
        let result = await timeTamperDetector.detectTimeTampering()
        
        // Then
        XCTAssertFalse(result.isTampered)
        XCTAssertEqual(result.detectionMethod, .networkSync)
        XCTAssertEqual(result.confidenceLevel, .high)
        XCTAssertNotNil(result.trustedTime)
    }
    
    func testDetectTimeTampering_WithNetworkTime_TamperingDetected() async throws {
        // Given
        let currentTime = Date()
        let networkTime = NetworkTimeResponse(
            serverTime: currentTime.addingTimeInterval(-600), // 10 minutes difference
            responseTime: 1.0,
            isReliable: true
        )
        mockNetworkService.mockNetworkTime = networkTime
        mockSystemService.setMockBootTime(currentTime.addingTimeInterval(-3600))
        
        // When
        let result = await timeTamperDetector.detectTimeTampering()
        
        // Then
        XCTAssertTrue(result.isTampered)
        XCTAssertEqual(result.detectionMethod, .networkSync)
        XCTAssertEqual(result.confidenceLevel, .high)
        XCTAssertNotNil(result.trustedTime)
    }
    
    func testDetectTimeTampering_WithUnreliableNetworkTime() async throws {
        // Given
        let currentTime = Date()
        let networkTime = NetworkTimeResponse(
            serverTime: currentTime.addingTimeInterval(30),
            responseTime: 8.0, // High response time
            isReliable: false
        )
        mockNetworkService.mockNetworkTime = networkTime
        
        // When
        let result = await timeTamperDetector.detectTimeTampering()
        
        // Then
        XCTAssertEqual(result.confidenceLevel, .low)
    }
    
    // MARK: - Stored Reference Detection Tests
    
    func testDetectTimeTampering_WithStoredReference_NoTampering() async throws {
        // Given
        let currentTime = Date()
        let bootTime = currentTime.addingTimeInterval(-3600) // 1 hour ago
        let storedReference = TrustedTimeReference(
            timestamp: currentTime.addingTimeInterval(-600), // 10 minutes ago
            bootTime: bootTime,
            deviceUptime: 3600,
            createdAt: currentTime.addingTimeInterval(-600),
            isValid: true
        )
        
        mockNetworkService.mockNetworkTime = nil // No network
        mockStorageService.mockTrustedReference = storedReference
        mockSystemService.setMockBootTime(bootTime)
        
        // When
        let result = await timeTamperDetector.detectTimeTampering()
        
        // Then
        XCTAssertFalse(result.isTampered)
        XCTAssertEqual(result.detectionMethod, .storedReference)
    }
    
    func testDetectTimeTampering_WithStoredReference_TamperingDetected() async throws {
        // Given
        let currentTime = Date()
        let bootTime = currentTime.addingTimeInterval(-3600)
        let storedReference = TrustedTimeReference(
            timestamp: currentTime.addingTimeInterval(-3600), // 1 hour ago, but with large drift
            bootTime: bootTime,
            deviceUptime: 3600,
            createdAt: currentTime.addingTimeInterval(-3600),
            isValid: true
        )
        
        mockNetworkService.mockNetworkTime = nil
        mockStorageService.mockTrustedReference = storedReference
        mockSystemService.setMockBootTime(bootTime)
        
        // When
        let result = await timeTamperDetector.detectTimeTampering()
        
        // Then
        // This should detect tampering due to time drift
        XCTAssertEqual(result.detectionMethod, .storedReference)
    }
    
    func testDetectTimeTampering_WithDeviceReboot() async throws {
        // Given
        let currentTime = Date()
        let oldBootTime = currentTime.addingTimeInterval(-7200) // 2 hours ago
        let newBootTime = currentTime.addingTimeInterval(-1800) // 30 minutes ago
        
        let storedReference = TrustedTimeReference(
            timestamp: currentTime.addingTimeInterval(-3600),
            bootTime: oldBootTime,
            deviceUptime: 3600,
            createdAt: currentTime.addingTimeInterval(-3600),
            isValid: true
        )
        
        mockNetworkService.mockNetworkTime = nil
        mockStorageService.mockTrustedReference = storedReference
        mockSystemService.setMockBootTime(newBootTime) // Different boot time
        
        // When
        let result = await timeTamperDetector.detectTimeTampering()
        
        // Then
        XCTAssertEqual(result.confidenceLevel, .low)
        XCTAssertEqual(result.detectionMethod, .storedReference)
    }
    
    // MARK: - Boot Time Tests
    
    func testGetSystemBootTime() {
        // Given
        let expectedBootTime = Date().addingTimeInterval(-3600)
        mockSystemService.setMockBootTime(expectedBootTime)
        
        // When
        let bootTime = timeTamperDetector.getSystemBootTime()
        
        // Then
        XCTAssertEqual(bootTime, expectedBootTime)
    }
    
    func testGetSystemBootTime_Unavailable() {
        // Given
        mockSystemService.setMockBootTime(nil)
        
        // When
        let bootTime = timeTamperDetector.getSystemBootTime()
        
        // Then
        XCTAssertNil(bootTime)
    }
    
    // MARK: - Integration Tests
    
    func testValidateTimeIntegrity_WithValidTime() async throws {
        // Given
        let currentTime = Date()
        let networkTime = NetworkTimeResponse(
            serverTime: currentTime.addingTimeInterval(10),
            responseTime: 1.0,
            isReliable: true
        )
        mockNetworkService.mockNetworkTime = networkTime
        
        // When
        let isValid = await timeTamperDetector.validateTimeIntegrity()
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func testValidateTimeIntegrity_WithTamperedTime() async throws {
        // Given
        let currentTime = Date()
        let networkTime = NetworkTimeResponse(
            serverTime: currentTime.addingTimeInterval(-1200), // 20 minutes difference
            responseTime: 1.0,
            isReliable: true
        )
        mockNetworkService.mockNetworkTime = networkTime
        
        // When
        let isValid = await timeTamperDetector.validateTimeIntegrity()
        
        // Then
        XCTAssertFalse(isValid)
    }
}
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
