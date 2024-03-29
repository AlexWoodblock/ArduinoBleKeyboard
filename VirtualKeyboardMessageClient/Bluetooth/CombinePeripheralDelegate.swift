//
//  CombinePeripheralDelegate.swift
//  VirtualKeyboardMessageClient
//
//  Created by Alexander Leontev on 17.06.23.
//

import Combine
import CoreBluetooth

/// Helper class taking role of `CBPeripheralDelegate` and applying reactivity to it.
class CombinePeripheralDelegate: NSObject, CBPeripheralDelegate {
    
    fileprivate enum DiscoveryResult {
        case discoverySucceeded
        case discoveryFailed(Error)
    }
    
    private let servicesDiscoveredSubject = PassthroughSubject<CombinePeripheralDelegate.DiscoveryResult, Never>()
    private let characteristicsDiscoveredSubject = PassthroughSubject<CombinePeripheralDelegate.DiscoveryResult, Never>()
    
    /// Suspend until characteristics of the peripheral are not discovered.
    /// May throw if discovery fails.
    func awaitCharacteristicsDiscovered() async throws {
        try await characteristicsDiscoveredSubject.awaitAndUnwrapResult()
    }
    
    /// Suspend until services of the peripheral are not discovered.
    /// May throw if discovery fails.
    func awaitServicesDiscovered() async throws {
        try await servicesDiscoveredSubject.awaitAndUnwrapResult()
    }
    
    // MARK: CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            logError("Failed to discover services, notifying...")
            servicesDiscoveredSubject.send(.discoveryFailed(error))
        } else {
            logInfo("Services discovered, notifying...")
            servicesDiscoveredSubject.send(.discoverySucceeded)
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        if let error = error {
            logError("Failed to discover characteristics, notifying...")
            characteristicsDiscoveredSubject.send(.discoveryFailed(error))
        } else {
            logInfo("Characteristics discovered, notifying...")
            characteristicsDiscoveredSubject.send(.discoverySucceeded)
        }
    }
}

fileprivate extension Publisher where Output == CombinePeripheralDelegate.DiscoveryResult,
                                      Failure == Never {
    
    func awaitAndUnwrapResult() async throws {
        let result = try await awaitFirst()
        
        switch result {
        case .discoveryFailed(let error):
            throw error
        case .discoverySucceeded:
            return
        }
    }
    
}
