//
//  TimeTamperViewModelTests.swift
//  Time Tamper DetectorTests
//
//  Created by Manoj Gadamsetty on 18/07/25.
//

import XCTest
@testable import Time_Tamper_Detector

@MainActor
final class TimeTamperViewModelTests: XCTestCase {
    
    var viewModel: TimeTamperViewModel!
    var mockDetector: MockTimeTamperDetector!
    
    override func setUpWithError() throws {
        super.setUp()
        mockDetector = MockTimeTamperDetector()
        viewModel = TimeTamperViewModel(detector: mockDetector)
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        mockDetector = nil
        super.tearDown()
    }
    
    // MARK: - Scan Tests
    
    func testStartScan_Success() async throws {
        // Given
        let expectedResult = TimeTamperResult(
            isTampered: false,
            deviceTime: Date(),
            trustedTime: Date(),
            bootTime: Date(),
            detectionMethod: .networkSync,
            confidenceLevel: .high,
            message: "Time integrity verified"
        )
        mockDetector.mockResult = expectedResult
        
        // When
        await viewModel.startScan()
        
        // Then
        XCTAssertFalse(viewModel.isScanning)
        XCTAssertEqual(viewModel.detectionResult?.isTampered, false)
        XCTAssertEqual(viewModel.detectionResult?.detectionMethod, .networkSync)
        XCTAssertEqual(viewModel.scanHistory.count, 1)
        XCTAssertEqual(viewModel.currentStatus, "Time Integrity Verified")
    }
    
    func testStartScan_TamperingDetected() async throws {
        // Given
        let expectedResult = TimeTamperResult(
            isTampered: true,
            deviceTime: Date(),
            trustedTime: Date().addingTimeInterval(-600),
            bootTime: Date(),
            detectionMethod: .networkSync,
            confidenceLevel: .high,
            message: "Time tampering detected"
        )
        mockDetector.mockResult = expectedResult
        
        // When
        await viewModel.startScan()
        
        // Then
        XCTAssertFalse(viewModel.isScanning)
        XCTAssertEqual(viewModel.detectionResult?.isTampered, true)
        XCTAssertEqual(viewModel.currentStatus, "Time Tampering Detected")
        XCTAssertEqual(viewModel.statusColor, .red)
    }
    
    func testStartScan_SetsIsScanning() async throws {
        // Given
        mockDetector.delay = 0.1 // Small delay to test isScanning state
        
        // When
        let scanTask = Task {
            await viewModel.startScan()
        }
        
        // Wait a bit and check isScanning
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        XCTAssertTrue(viewModel.isScanning)
        
        await scanTask.value
        XCTAssertFalse(viewModel.isScanning)
    }
    
    // MARK: - History Tests
    
    func testClearHistory() {
        // Given
        let result1 = createMockResult(isTampered: false)
        let result2 = createMockResult(isTampered: true)
        viewModel.scanHistory = [result1, result2]
        
        // When
        viewModel.clearHistory()
        
        // Then
        XCTAssertTrue(viewModel.scanHistory.isEmpty)
    }
    
    func testExportScanHistory() {
        // Given
        let result = createMockResult(isTampered: false)
        viewModel.scanHistory = [result]
        
        // When
        let exportedData = viewModel.exportScanHistory()
        
        // Then
        XCTAssertFalse(exportedData.isEmpty)
        XCTAssertTrue(exportedData.contains("isTampered"))
    }
    
    // MARK: - Computed Properties Tests
    
    func testStatusColor_NoResult() {
        // Given
        viewModel.detectionResult = nil
        
        // When & Then
        XCTAssertEqual(viewModel.statusColor, .blue)
    }
    
    func testStatusColor_TamperingDetected() {
        // Given
        viewModel.detectionResult = createMockResult(isTampered: true)
        
        // When & Then
        XCTAssertEqual(viewModel.statusColor, .red)
    }
    
    func testStatusColor_HighConfidence() {
        // Given
        viewModel.detectionResult = createMockResult(
            isTampered: false,
            confidenceLevel: .high
        )
        
        // When & Then
        XCTAssertEqual(viewModel.statusColor, .green)
    }
    
    func testStatusColor_MediumConfidence() {
        // Given
        viewModel.detectionResult = createMockResult(
            isTampered: false,
            confidenceLevel: .medium
        )
        
        // When & Then
        XCTAssertEqual(viewModel.statusColor, .orange)
    }
    
    func testStatusColor_LowConfidence() {
        // Given
        viewModel.detectionResult = createMockResult(
            isTampered: false,
            confidenceLevel: .low
        )
        
        // When & Then
        XCTAssertEqual(viewModel.statusColor, .yellow)
    }
    
    func testConfidenceText() {
        // Test high confidence
        viewModel.detectionResult = createMockResult(confidenceLevel: .high)
        XCTAssertEqual(viewModel.confidenceText, "High Confidence")
        
        // Test medium confidence
        viewModel.detectionResult = createMockResult(confidenceLevel: .medium)
        XCTAssertEqual(viewModel.confidenceText, "Medium Confidence")
        
        // Test low confidence
        viewModel.detectionResult = createMockResult(confidenceLevel: .low)
        XCTAssertEqual(viewModel.confidenceText, "Low Confidence")
    }
    
    func testDetectionMethodText() {
        // Test network sync
        viewModel.detectionResult = createMockResult(detectionMethod: .networkSync)
        XCTAssertEqual(viewModel.detectionMethodText, "Network Synchronization")
        
        // Test stored reference
        viewModel.detectionResult = createMockResult(detectionMethod: .storedReference)
        XCTAssertEqual(viewModel.detectionMethodText, "Stored Reference")
        
        // Test boot time analysis
        viewModel.detectionResult = createMockResult(detectionMethod: .bootTimeAnalysis)
        XCTAssertEqual(viewModel.detectionMethodText, "Boot Time Analysis")
        
        // Test combined
        viewModel.detectionResult = createMockResult(detectionMethod: .combined)
        XCTAssertEqual(viewModel.detectionMethodText, "Combined Analysis")
    }
    
    // MARK: - Helper Methods
    
    private func createMockResult(
        isTampered: Bool = false,
        detectionMethod: TimeTamperResult.DetectionMethod = .networkSync,
        confidenceLevel: TimeTamperResult.ConfidenceLevel = .high
    ) -> TimeTamperResult {
        return TimeTamperResult(
            isTampered: isTampered,
            deviceTime: Date(),
            trustedTime: Date(),
            bootTime: Date(),
            detectionMethod: detectionMethod,
            confidenceLevel: confidenceLevel,
            message: "Test message"
        )
    }
}

// MARK: - Mock Time Tamper Detector

class MockTimeTamperDetector: TimeTamperDetectorProtocol {
    var mockResult: TimeTamperResult?
    var delay: TimeInterval = 0
    var shouldThrowError = false
    var mockBootTime: Date?
    var mockNetworkTime: NetworkTimeResponse?
    
    func detectTimeTampering() async -> TimeTamperResult {
        if delay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if shouldThrowError {
            // Since the protocol doesn't throw, we'll return a default result
            return TimeTamperResult(
                isTampered: false,
                deviceTime: Date(),
                trustedTime: nil,
                bootTime: nil,
                detectionMethod: .bootTimeAnalysis,
                confidenceLevel: .low,
                message: "Error occurred during detection"
            )
        }
        
        return mockResult ?? TimeTamperResult(
            isTampered: false,
            deviceTime: Date(),
            trustedTime: Date(),
            bootTime: Date(),
            detectionMethod: .networkSync,
            confidenceLevel: .high,
            message: "Default test result"
        )
    }
    
    func validateTimeIntegrity() async -> Bool {
        let result = await detectTimeTampering()
        return !result.isTampered
    }
    
    func getSystemBootTime() -> Date? {
        return mockBootTime
    }
    
    func getTrustedNetworkTime() async -> NetworkTimeResponse? {
        return mockNetworkTime
    }
}
