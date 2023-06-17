//
//  CombineCBManagerDelegate.swift
//  VirtualKeyboardMessageClient
//
//  Created by Alexander Leontev on 17.06.23.
//

import Combine
import CoreBluetooth

/// Helper class taking role of `CBCentralManagerDelegate` and applying reactivity to it.
class CombineBluetoothDelegate: NSObject, CBCentralManagerDelegate {
    
    // global BLE state subjects
    private let stateSubject = CurrentValueSubject<CBManagerState, Never>(CBManagerState.unknown)
    
    // connection state subjects
    private let discoveredPeripheralSubject = CurrentValueSubject<CBPeripheral?, Never>(nil)
    private let isConnectedToPeripheralSubject = CurrentValueSubject<Bool, Never>(false)
    
    var statePublisher: AnyPublisher<CBManagerState, Never> {
        return stateSubject.eraseToAnyPublisher()
    }
    
    /// Publisher emitting discovered `CBPeripheral`s.
    /// Emits current value on subscription.
    var discoveredPeripheralPublisher: AnyPublisher<CBPeripheral?, Never> {
        return discoveredPeripheralSubject.eraseToAnyPublisher()
    }
    
    /// Publisher emitting `true` if we're connected and `false` if we're not.
    /// Emits current value on subscription.
    var isConnectedPublisher: AnyPublisher<Bool, Never> {
        return isConnectedToPeripheralSubject.eraseToAnyPublisher()
    }
    
    /// Returns current connected peripheral (if there are any).
    var connectedPeripheral: CBPeripheral? {
        return discoveredPeripheralSubject.value
    }
    
    /// Rest the state of the delegate. Should be called when disconnecting.
    func clear() {
        logInfo("Clearing Bluetooth delegate")
        
        discoveredPeripheralSubject.send(nil)
        isConnectedToPeripheralSubject.send(false)
    }
    
    // MARK: CBCentralManagerDelegate
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        logInfo("Peripheral \(peripheral.name ?? "[no name]") discovered, notifying...")
        
        discoveredPeripheralSubject.send(peripheral)
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        logInfo("Peripheral connected, notifying...")
        
        isConnectedToPeripheralSubject.send(true)
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        logInfo("Peripheral disconnected, notifying...")
        
        discoveredPeripheralSubject.send(nil)
        isConnectedToPeripheralSubject.send(false)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state
        logInfo("New Bluetooth manager state: \(state)")
        stateSubject.send(state)
    }
    
    
}
