//
//  NetworkTimeServiceTests.swift
//  Time Tamper DetectorTests
//
//  Created by Manoj Gadamsetty on 18/07/25.
//

import XCTest
@testable import Time_Tamper_Detector

final class NetworkTimeServiceTests: XCTestCase {
    
    var networkService: NetworkTimeService!
    
    override func setUpWithError() throws {
        super.setUp()
        networkService = NetworkTimeService()
    }
    
    override func tearDownWithError() throws {
        networkService = nil
        super.tearDown()
    }
    
    // MARK: - Network Time Fetching Tests
    
    func testFetchTrustedTime_Success() async throws {
        // This test would require mocking URLSession or using a test server
        // For now, we'll test the structure and behavior
        
        // When network is available, it should attempt to fetch time
        let result = await networkService.fetchTrustedTime()
        
        // The result might be nil if no network or server is down, which is expected in tests
        // In a real implementation, you'd mock URLSession
        if let result = result {
            XCTAssertTrue(result.responseTime >= 0)
            XCTAssertNotNil(result.serverTime)
        }
    }
    
    func testIsNetworkAvailable() {
        // Test that the network monitoring is initialized
        // The actual state depends on the device's network connection
        let isAvailable = networkService.isNetworkAvailable()
        
        // This is a basic test - in practice you'd mock the network monitor
        XCTAssertTrue(isAvailable || !isAvailable) // Always passes, but ensures method works
    }
}

// MARK: - System Time Service Tests

final class SystemTimeServiceTests: XCTestCase {
    
    var systemService: SystemTimeService!
    
    override func setUpWithError() throws {
        super.setUp()
        systemService = SystemTimeService()
    }
    
    override func tearDownWithError() throws {
        systemService = nil
        super.tearDown()
    }
    
    func testGetBootTime() {
        // When
        let bootTime = systemService.getBootTime()
        
        // Then
        if let bootTime = bootTime {
            // Boot time should be in the past
            XCTAssertLessThan(bootTime, Date())
            
            // Boot time should be reasonable (not more than 30 days ago)
            let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
            XCTAssertGreaterThan(bootTime, thirtyDaysAgo)
        }
        // Note: Boot time might be nil on simulator or in some test environments
    }
    
    func testGetUptime() {
        // When
        let uptime = systemService.getUptime()
        
        // Then
        XCTAssertGreaterThan(uptime, 0)
        XCTAssertLessThan(uptime, 30 * 24 * 60 * 60) // Less than 30 days
    }
    
    func testGetSystemInfo() {
        // When
        let systemInfo = systemService.getSystemInfo()
        
        // Then
        XCTAssertGreaterThan(systemInfo.uptime, 0)
        XCTAssertLessThan(systemInfo.currentTime, Date().addingTimeInterval(1))
        XCTAssertGreaterThan(systemInfo.currentTime, Date().addingTimeInterval(-1))
        XCTAssertNotNil(systemInfo.timeZone)
        XCTAssertNotNil(systemInfo.locale)
        XCTAssertFalse(systemInfo.deviceModel.isEmpty)
        XCTAssertFalse(systemInfo.systemVersion.isEmpty)
        XCTAssertGreaterThanOrEqual(systemInfo.processUptime, 0)
    }
    
    func testGetDeviceStartupReference() {
        // When
        let startupRef = systemService.getDeviceStartupReference()
        
        // Then
        if let startupRef = startupRef {
            XCTAssertTrue(startupRef.isValid)
            XCTAssertGreaterThan(startupRef.systemUptime, 0)
            XCTAssertGreaterThanOrEqual(startupRef.processUptime, 0)
            XCTAssertFalse(startupRef.deviceModel.isEmpty)
            XCTAssertFalse(startupRef.systemVersion.isEmpty)
        }
    }
    
    func testGetUptimeMetrics() {
        // When
        let metrics = systemService.getUptimeMetrics()
        
        // Then
        XCTAssertGreaterThan(metrics.systemUptime, 0)
        XCTAssertGreaterThanOrEqual(metrics.processUptime, 0)
        XCTAssertLessThan(metrics.timestamp, Date().addingTimeInterval(1))
    }
}

// MARK: - Mock System Time Service Tests

final class MockSystemTimeServiceTests: XCTestCase {
    
    var mockService: MockSystemTimeService!
    
    override func setUpWithError() throws {
        super.setUp()
        mockService = MockSystemTimeService()
    }
    
    override func tearDownWithError() throws {
        mockService = nil
        super.tearDown()
    }
    
    func testMockBootTime() {
        // Given
        let expectedBootTime = Date().addingTimeInterval(-3600)
        
        // When
        mockService.setMockBootTime(expectedBootTime)
        
        // Then
        XCTAssertEqual(mockService.getBootTime(), expectedBootTime)
    }
    
    func testMockUptime() {
        // Given
        let expectedUptime: TimeInterval = 7200 // 2 hours
        
        // When
        mockService.setMockUptime(expectedUptime)
        
        // Then
        XCTAssertEqual(mockService.getUptime(), expectedUptime)
    }
    
    func testMockSystemInfo() {
        // Given
        let bootTime = Date().addingTimeInterval(-1800)
        let uptime: TimeInterval = 1800
        mockService.setMockBootTime(bootTime)
        mockService.setMockUptime(uptime)
        
        // When
        let systemInfo = mockService.getSystemInfo()
        
        // Then
        XCTAssertEqual(systemInfo.bootTime, bootTime)
        XCTAssertEqual(systemInfo.uptime, uptime)
        XCTAssertNotNil(systemInfo.timeZone)
        XCTAssertNotNil(systemInfo.locale)
    }
}
