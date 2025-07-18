//
//  NetworkTimeService.swift
//  Time Tamper Detector
//
//  Created by Manoj Gadamsetty on 18/07/25.
//

import Foundation
import Network

// MARK: - Network Time Service Protocol

protocol NetworkTimeServiceProtocol {
    func fetchTrustedTime() async -> NetworkTimeResponse?
    func isNetworkAvailable() -> Bool
}

// MARK: - Network Time Service Implementation

class NetworkTimeService: NetworkTimeServiceProtocol {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkTimeService")
    private var isConnected = false
    
    init() {
        startNetworkMonitoring()
    }
    
    func fetchTrustedTime() async -> NetworkTimeResponse? {
        guard isNetworkAvailable() else {
            return nil
        }
        
        // Try multiple time servers for redundancy
        for server in TimeTamperConfig.trustedTimeServers {
            if let response = await fetchTimeFromServer(server) {
                return response
            }
        }
        
        return nil
    }
    
    func isNetworkAvailable() -> Bool {
        return isConnected
    }
    
    // MARK: - Private Methods
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = path.status == .satisfied
        }
        monitor.start(queue: queue)
    }
    
    private func fetchTimeFromServer(_ server: String) async -> NetworkTimeResponse? {
        let startTime = Date()
        
        do {
            // Use WorldTimeAPI for reliable time service
            let urlString = "https://worldtimeapi.org/api/timezone/Etc/UTC"
            guard let url = URL(string: urlString) else {
                return nil
            }
            
            var request = URLRequest(url: url)
            request.timeoutInterval = TimeTamperConfig.networkTimeoutDuration
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            let responseTime = Date().timeIntervalSince(startTime)
            
            if let serverTime = parseTimeFromResponse(data) {
                return NetworkTimeResponse(
                    serverTime: serverTime,
                    responseTime: responseTime,
                    isReliable: responseTime < 5.0
                )
            }
            
        } catch {
            print("Network time fetch error: \(error)")
        }
        
        return nil
    }
    
    private func parseTimeFromResponse(_ data: Data) -> Date? {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let datetimeString = json["datetime"] as? String {
                
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                return formatter.date(from: datetimeString)
            }
        } catch {
            print("JSON parsing error: \(error)")
        }
        
        return nil
    }
    
    deinit {
        monitor.cancel()
    }
}
