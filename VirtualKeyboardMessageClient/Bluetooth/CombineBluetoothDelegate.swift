//
//  CombineCBManagerDelegate.swift
//  VirtualKeyboardMessageClient
//
//  Created by Alexander Leontev on 17.06.23.
//

import Combine
import CoreBluetooth

class CombineBluetoothDelegate: NSObject, CBCentralManagerDelegate {
    
    // global BLE state subjects
    private let stateSubject = CurrentValueSubject<CBManagerState, Never>(CBManagerState.unknown)
    
    // connection state subjects
    private let discoveredPeripheralSubject = CurrentValueSubject<CBPeripheral?, Never>(nil)
    private let isConnectedToPeripheralSubject = CurrentValueSubject<Bool, Never>(false)
    
    var statePublisher: AnyPublisher<CBManagerState, Never> {
        return stateSubject.eraseToAnyPublisher()
    }
    
    var discoveredPeripheralPublisher: AnyPublisher<CBPeripheral?, Never> {
        return discoveredPeripheralSubject.eraseToAnyPublisher()
    }
    
    var isConnectedPublisher: AnyPublisher<Bool, Never> {
        return isConnectedToPeripheralSubject.eraseToAnyPublisher()
    }
    
    var connectedPeripheral: CBPeripheral? {
        return discoveredPeripheralSubject.value
    }
    
    func clear() {
        logInfo("Clearing Bluetooth delegate")
        
        discoveredPeripheralSubject.send(nil)
        isConnectedToPeripheralSubject.send(false)
    }
    
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
