//
//  AppView.swift
//  VirtualKeyboardMessageClient
//
//  Created by Alexander Leontev on 12.06.23.
//

import Combine
import SwiftUI

/// Main view for the app.
struct AppView: View {
    
    let keyEventSignalPublisher: AnyPublisher<(), Never>
    let bleState: BluetoothInteractor.ConnectionState
    let onCaptureSettingChanged: ((Bool) -> Void)?
    let sizeReporter: (CGFloat, CGFloat) -> Void
    
    @State
    private var captureIsOn = false
    
    var body: some View {
        GeometryReader { proxy in
            ConnectivityView(
                keyEventSignalPublisher: keyEventSignalPublisher,
                connectivityState: connectivityState(),
                captureIsOn: $captureIsOn
            )
            .animation(.default, value: captureIsOn)
            .onChange(of: captureIsOn) { newValue in
                onCaptureSettingChanged?(newValue)
            }
            .padding()
            .background(.blue.opacity(0.2))
            .background(.ultraThinMaterial)
            .sizeReader { width, height in
                sizeReporter(width, height)
            }
        }
    }
    
    private func connectivityState() -> ConnectivityView.ConnectivityState {
        switch bleState {
        case .connected:
            return .connected
        case .connecting:
            return .connecting
        case .searching:
            return .searching
        case .disconnected:
            return .disconnected
        case .off:
            return .off
        }
        
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(
            keyEventSignalPublisher: Empty<(), Never>(completeImmediately: false).eraseToAnyPublisher(),
            bleState: .connected,
            onCaptureSettingChanged: { _ in },
            sizeReporter: { (width, height) in }
        )
    }
}
#endif
