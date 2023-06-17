//
//  BluetoothManager.swift
//  VirtualKeyboardMessageClient
//
//  Created by Alexander Leontev on 13.06.23.
//

import Combine
import CoreBluetooth

/// Interactor responsible for communications between the application and keyboard emulator.
class BluetoothInteractor {
    
    // MARK: Inner classes
    private enum Errors: Error {
        case noExpectedServiceError
        case noExpectedCharacteristicError
        case unexpectedInputStreamEnd
        case connectionLost
    }
    
    /// All possible connection states.
    enum ConnectionState {
        
        /// Connection can be established, but user currently chose not to.
        case disconnected
        
        /// Searching for the device.
        case searching
        
        /// Device is found, establishing BLE connection and discovering characteristics and services.
        case connecting
        
        /// Connection established and characteristics are discovered - ready to send key presses.
        case connected
        
        /// BLE is off on the device or permission is denied.
        case off
    }
    
    // MARK: Constants
    private static let bufferSize = 256
    
    private static let errorRetryInterval = Duration.seconds(1)
    private static let connectionSwitchesDebounceInterval = Duration.milliseconds(250)
    
    private static let messageService = CBUUID(string: "98AD")
    private static let messageTxCharacteristic = CBUUID(string: "98AF")
    
    // MARK: Fields
    private let manager = CBCentralManager()
    private let connectionDesiredSubject = CurrentValueSubject<Bool, Never>(false)
    private var interactorCancellables = Set<AnyCancellable>()
    
    private let bluetoothDelegate = CombineBluetoothDelegate()
    private let peripheralDelegate = CombinePeripheralDelegate()
    
    private let bleOperationsSerialQueue = DispatchQueue(
        label: "BleOperationsSerialQueue",
        qos: .userInitiated
    )
    
    // State subjects
    private let readyForCommandsSubject = CurrentValueSubject<Bool, Never>(false)
    
    // Notification subjects
    private let suddenDisconnectionSubject = PassthroughSubject<Void, Never>()
    
    // input
    private let inputSubject = PassthroughSubject<KeyPress, Never>()
    
    // Transient state
    private var activeConnectionTask: Task<Void, Error>? = nil
    
    init() {
        manager.delegate = bluetoothDelegate
        observeConnection()
        observeSuddenDisconnections()
    }
    
    /// Publisher emitting current connection state.
    func statePublisher() -> AnyPublisher<ConnectionState, Never> {
        return combineLatest(
            bluetoothDelegate.statePublisher,
            readyForCommandsSubject.eraseToAnyPublisher(),
            bluetoothDelegate.discoveredPeripheralPublisher,
            bluetoothDelegate.isConnectedPublisher.eraseToAnyPublisher(),
            connectionDesiredSubject.eraseToAnyPublisher()
        ) { (state, readyForCommand, discoveredPeripheral, isConnected, connectionDesired) in
            if state != .poweredOn {
                return ConnectionState.off
            }
            
            if !connectionDesired {
                return ConnectionState.disconnected
            }
            
            if discoveredPeripheral == nil {
                return ConnectionState.searching
            }
            
            if !isConnected || !readyForCommand {
                return ConnectionState.connecting
            }
            
            return .connected
        }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }
    
    private func observeSuddenDisconnections() {
        connectionDesiredSubject
            .removeDuplicates()
            .map { [unowned self] isConnectionDesired in
                if isConnectionDesired {
                    return self.bluetoothDelegate
                        .isConnectedPublisher
                        .withPrevious()
                        .map { connectedTuple in
                            let (wasConnectedBefore, isConnectedNow) = connectedTuple
                            return wasConnectedBefore && !isConnectedNow
                        }
                        .eraseToAnyPublisher()
                } else {
                    return Empty<Bool, Never>()
                        .eraseToAnyPublisher()
                }
            }
            .switchToLatest()
            .filter { connectionLost in connectionLost }
            .sink { [unowned self] _ in
                self.suddenDisconnectionSubject.send(())
            }
            .store(in: &interactorCancellables)
        
    }
    
    private func observeConnection() {
        connectionDesiredSubject
            .removeDuplicates()
            .receive(on: bleOperationsSerialQueue)
            .sink(receiveValue: { [unowned self] connectionDesired in
                if connectionDesired {
                    guard activeConnectionTask == nil else {
                        return
                    }
                    
                    activeConnectionTask = createConnectionTask()
                } else {
                    activeConnectionTask?.cancel()
                    activeConnectionTask = nil
                }
            })
            .store(in: &interactorCancellables)
    }
    
    /// Set in which state user desires to see the connection.
    /// If `true`, we'll make best efforts to connect to the device.
    /// If `false`, any active connections will be cleared and all attempts to connect will be stopped.
    func set(shouldBeConnected: Bool) {
        connectionDesiredSubject.send(shouldBeConnected)
    }
    
    /// Attempts to send input to BLE device.
    /// Returns immediately, send is not guaranteed - listen to current state to determine if send can be performed.
    func send(keyPress: KeyPress) {
        inputSubject.send(keyPress)
    }
    
    private func createConnectionTask() -> Task<Void, Error> {
        return Task {
            while (!Task.isCancelled) {
                do {
                    try await connect()
                } catch (let e) {
                    logError("An error occurred during connection: \(e)")
                    
                    try await Task.sleep(
                        until: .now + BluetoothInteractor.errorRetryInterval,
                        clock: .suspending
                    )
                }
            }
        }
    }
    
    private func connect() async throws {
        try await withTaskCancellationHandler {
            try await waitBluetoothPoweredOn()
            logInfo("BLE is powered on, looking for device...")
            
            let device = try await findDevice()
            device.delegate = peripheralDelegate
            logInfo("Device found, connecting...")
            
            try await connect(toDevice: device)
            
            logInfo("Connected! Discovering service...")
            let service = try await discoverService(onDevice: device)
            
            logInfo("Got the service! Discovering TX characteristic...")
            let characteristic = try await discoverTxCharacteristic(onDevice: device, inService: service)
            
            logInfo("Characteristic found! Ready for writing!")
            
            readyForCommandsSubject.send(true)
            
            try await inputSubject
                .setFailureType(to: Error.self)
                .buffer(
                    size: BluetoothInteractor.bufferSize,
                    prefetch: .byRequest,
                    whenFull: .dropNewest
                )
                // this will cause connection restart on sudden disconnections
                .merge(
                    with: suddenDisconnectionSubject
                        .tryMap { _ in
                            // we don't emit error directly into subject to avoid it breaking
                            // after first error
                            throw Errors.connectionLost
                        }
                        .cast()
                )
                .receive(on: bleOperationsSerialQueue)
                .awaitSink(receiveValue: { keyPress in
                    device.writeValue(
                        keyPress.data(),
                        for: characteristic,
                        type: .withoutResponse
                    )
                })
            
            throw Errors.unexpectedInputStreamEnd
        } onCancel: {
            logInfo("Task cancelled! Clearing connection...")
            
            if let activePeripheral = bluetoothDelegate.connectedPeripheral {
                manager.cancelPeripheralConnection(activePeripheral)
            }
            
            readyForCommandsSubject.send(false)
            bluetoothDelegate.clear()
        }
    }
    
    private func waitBluetoothPoweredOn() async throws {
        _ = try await bluetoothDelegate
            .statePublisher
            .first { state in state == .poweredOn }.awaitFirst()
    }
    
    private func findDevice() async throws -> CBPeripheral {
        defer {
            manager.stopScan()
        }
        
        manager.scanForPeripherals(withServices: [
            BluetoothInteractor.messageService
        ])
        
        return try await bluetoothDelegate
            .discoveredPeripheralPublisher
            .compactMap { $0 }
            .awaitFirst()
    }
    
    private func connect(toDevice device: CBPeripheral) async throws {
        manager.connect(device)
        
        _ = try await bluetoothDelegate.isConnectedPublisher
            .first { isConnected in isConnected }
            .awaitFirst()
    }
    
    private func discoverService(onDevice device: CBPeripheral) async throws -> CBService {
        device.discoverServices(nil)
        
        try await peripheralDelegate.awaitServicesDiscovered()
        
        guard let service = device.services?.first(where: { service in
            service.uuid == BluetoothInteractor.messageService
        }) else {
            throw Errors.noExpectedServiceError
        }
        
        return service
    }
    
    private func discoverTxCharacteristic(
        onDevice device: CBPeripheral,
        inService service: CBService
    ) async throws -> CBCharacteristic {
        device.discoverCharacteristics([
            BluetoothInteractor.messageTxCharacteristic
        ], for: service)
        
        try await peripheralDelegate.awaitCharacteristicsDiscovered()
        
        guard let characteristic = service.characteristics?.first(where: { characteristic in
            characteristic.uuid == BluetoothInteractor.messageTxCharacteristic
        }) else {
            throw Errors.noExpectedCharacteristicError
        }
        
        return characteristic
    }
}
