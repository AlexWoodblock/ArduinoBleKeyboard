//
//  AppView.swift
//  VirtualKeyboardMessageClient
//
//  Created by Alexander Leontev on 12.06.23.
//

import SwiftUI

/// Main view for the app.
struct AppView: View {
    
    private let bleState: BluetoothInteractor.ConnectionState
    private let onCaptureSettingChanged: ((Bool) -> Void)?
    
    init(
        bleState: BluetoothInteractor.ConnectionState = .off,
        onCaptureSettingChanged: ((Bool) -> Void)? = nil
    ) {
        self.bleState = bleState
        self.onCaptureSettingChanged = onCaptureSettingChanged
    }
    
    @State
    private var captureIsOn = false
    
    var body: some View {
        VStack(alignment: .leading) {
            ConnectivityView(
                connectivityState: connectivityState(),
                captureIsOn: $captureIsOn
            )
        }
        .animation(.default, value: captureIsOn)
        .padding()
        .onChange(of: captureIsOn) { newValue in
            onCaptureSettingChanged?(newValue)
        }
        .background(.blue.opacity(0.2))
        .background(.ultraThinMaterial)
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
        AppView()
    }
}
#endif
