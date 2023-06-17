//
//  VirtualKeyboardMessageClientApp.swift
//  VirtualKeyboardMessageClient
//
//  Created by Alexander Leontev on 12.06.23.
//

import Combine
import SwiftUI

@main
struct VirtualKeyboardMessageClientApp: App {
    
    private enum FocusTarget: Int, Hashable {
        case wholeApp = 0
    }
    
    @FocusState
    private var focusTarget: FocusTarget?
    
    private let keyEventMonitoringInteractor = KeyEventMonitoringInteractor()
    private let bluetoothInteractor = BluetoothInteractor()
    
    @State
    private var bleState = BluetoothInteractor.ConnectionState.off
    
    var body: some Scene {
        WindowGroup {
            AppView(
                bleState: bleState,
                onCaptureSettingChanged: on(captureEnabled:)
            )
            .onReceive(
                bluetoothInteractor
                    .statePublisher()
                    .receive(on: DispatchQueue.main)
            ) { bleConnectionState in
                self.bleState = bleConnectionState
            }
            .focused($focusTarget, equals: FocusTarget.wholeApp)
            .onAppear {
                makeWindowsTransparent()
                setupKeyListener()
            }
        }
        .windowResizability(.contentSize)
    }
    
    private func on(captureEnabled: Bool) {
        keyEventMonitoringInteractor.setCapture(enabled: captureEnabled)
        
        // if we enable it, make the app grab the focus
        if captureEnabled {
            focusTarget = .wholeApp
        } else {
            focusTarget = nil
        }
        
        bluetoothInteractor.set(shouldBeConnected: captureEnabled)
    }
    
    private func makeWindowsTransparent() {
        DispatchQueue.main.async {
            NSApp.windows.forEach {
                $0.isOpaque = false
                $0.backgroundColor = .clear
            }
        }
    }
    
    private func setupKeyListener() {
        keyEventMonitoringInteractor.onCapturedEvent = { event in
            bluetoothInteractor.send(keyPress: KeyPress(event: event))
        }
    }
}
