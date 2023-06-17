//
//  ConnectivityView.swift
//  VirtualKeyboardMessageClient
//
//  Created by Alexander Leontev on 16.06.23.
//

import SwiftUI

// TODO: fix resizing and text being partially hidden!
/// View displaying connectivity between your computer and the keyboard emulator.
struct ConnectivityView: View {
    
    private static let animationStepDuration = Duration.milliseconds(250)
    private static let animationStepsCount = 4
    
    /// The state describing current connection between the application
    /// and the keyboard emulator
    enum ConnectivityState {
        case off
        case disconnected
        case searching
        case connecting
        case connected
    }
    
    let connectivityState: ConnectivityState
    
    @State
    private var connectionAnimationStep = 0
    
    @Binding
    var captureIsOn: Bool
    
    var body: some View {
        VStack {
            HStack {
                ZStack {
                    Image(systemName: "laptopcomputer")
                        .font(.system(size: 72.0))
                        .foregroundColor(.green)
                    
                    Toggle(isOn: $captureIsOn) {}
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                
                Spacer().frame(width: 32.0)
                
                Image(
                    systemName: "wave.3.right",
                    variableValue: animationValue()
                )
                .foregroundColor(accentColor())
                .font(.system(size: 36.0))
                .animation(.linear, value: connectionAnimationStep)
                
                Spacer().frame(width: 32.0)
                
                
                Image(systemName: "keyboard")
                    .font(.system(size: 72.0))
                    .foregroundColor(accentColor())
            }
            .frame(minWidth: 256)
            
            Spacer().frame(height: 8.0)
            
            Text(connectionText())
        }
        .task(id: connectivityState) {
            guard connectionAnimated() else {
                connectionAnimationStep = ConnectivityView.animationStepsCount - 1
                return
            }
            
            while (!Task.isCancelled) {
                connectionAnimationStep = (connectionAnimationStep + 1) % ConnectivityView.animationStepsCount
                try? await Task.sleep(for: ConnectivityView.animationStepDuration)
            }
        }
    }
    
    private func connectionText() -> LocalizedStringKey {
        switch connectivityState {
        case .connecting:
            return "connection.state.connecting"
        case .off:
            return "connection.state.off"
        case .searching:
            return "connection.state.searching"
        case .disconnected:
            return "connection.state.disconnected"
        case .connected:
            return "connection.state.connected"
        }
    }
    
    private func animationValue() -> Double {
        return Double(connectionAnimationStep) / Double(ConnectivityView.animationStepsCount)
    }
    
    private func connectionAnimated() -> Bool {
        switch connectivityState {
        case .connecting:
            return true
        case .off:
            return false
        case .searching:
            return true
        case .disconnected:
            return false
        case .connected:
            return false
        }
    }
    
    private func accentColor() -> Color {
        switch connectivityState {
        case .searching:
            return .blue
        case .connected:
            return .green
        case .connecting:
            return .cyan
        case .disconnected:
            return .gray
        case .off:
            return .red
        }
    }
}

#if DEBUG
struct ConnectivityView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectivityView(connectivityState: .searching, captureIsOn: Binding.constant(true))
    }
}
#endif
