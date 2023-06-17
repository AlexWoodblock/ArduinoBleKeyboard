//
//  VirtualKeyboardMessageClientApp.swift
//  VirtualKeyboardMessageClient
//
//  Created by Alexander Leontev on 12.06.23.
//

import Combine
import SwiftUI

/// Main application class.
@main
struct VirtualKeyboardMessageClientApp: App {
    
    private static let windowSizeEstimate: CGFloat = 600
    
    private enum FocusTarget: Int, Hashable {
        case wholeApp = 0
    }
    
    @FocusState
    private var focusTarget: FocusTarget?
    
    private let keyEventMonitoringInteractor = KeyEventMonitoringInteractor()
    private let bluetoothInteractor = BluetoothInteractor()
    
    @State
    private var bleState = BluetoothInteractor.ConnectionState.off
    
    // Either SwiftUI interaction with windows is horrible,
    // or I am missing something.
    // Trying everything to not allow SwiftUI to compress my window ended in vain - it allowed the content to be compressed
    // and partially hidden.
    //
    // What I'm doing here is setting the size to fixed one by doing this:
    // 1. Set initial size to something sensible
    // 2. Read size of actual content view through GeometryReader
    // 3. Set this fixed size to the window so it will have correct size.
    @State
    private var windowHeight = VirtualKeyboardMessageClientApp.windowSizeEstimate
    
    @State
    private var windowWidth = VirtualKeyboardMessageClientApp.windowSizeEstimate
    
    var body: some Scene {
        WindowGroup {
            AppView(
                keyEventSignalPublisher: keyEventMonitoringInteractor
                    .capturedEventPublisher
                    .map { _ in () }
                    .eraseToAnyPublisher(),
                bleState: bleState,
                onCaptureSettingChanged: on(captureEnabled:),
                sizeReporter: { width, height in
                    windowWidth = width
                    windowHeight = height
                }
            )
            .onReceive(
                bluetoothInteractor
                    .statePublisher()
                    .receive(on: DispatchQueue.main)
            ) { bleConnectionState in
                self.bleState = bleConnectionState
            }
            .onReceive(
                keyEventMonitoringInteractor.capturedEventPublisher.map { KeyPress(event: $0) },
                perform: bluetoothInteractor.send(keyPress:)
            )
            .focused($focusTarget, equals: FocusTarget.wholeApp)
            .onAppear {
                makeWindowsTransparent()
            }
            .navigationTitle("window.title")
            .frame(
                minWidth: windowWidth,
                maxWidth: windowWidth,
                minHeight: windowHeight,
                maxHeight: windowHeight
            )
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
}
