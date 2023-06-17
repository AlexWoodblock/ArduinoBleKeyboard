//
//  ConnectivityView.swift
//  VirtualKeyboardMessageClient
//
//  Created by Alexander Leontev on 16.06.23.
//

import Combine
import SwiftUI

/// View displaying connectivity between your computer and the keyboard emulator.
struct ConnectivityView: View {
    
    private static let animationAfterTypingDuration = Duration.milliseconds(200)
    private static let sendingStepAnimationDuration = Duration.milliseconds(100)

    private static let connectivityStepAnimationDuration = Duration.milliseconds(250)
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
    
    private enum AnimationState {
        case none
        case connectivity
        case sending
    }
    
    let keyEventSignalPublisher: AnyPublisher<Void, Never>
    
    let connectivityState: ConnectivityState
    
    @State
    private var typedLastTimeAt = Date.distantPast
    
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
                
                
                Image(systemName: keyboardSymbolName())
                    .font(.system(size: 72.0))
                    .foregroundColor(accentColor())
            }
            .frame(minWidth: 256)
            
            Spacer().frame(height: 8.0)
            
            Text(connectionText())
        }
        .onReceive(
            keyEventSignalPublisher,
            perform: { _ in
                typedLastTimeAt = Date.now
            }
        )
        .task(id: animationState()) {
            switch animationState() {
            case .none:
                connectionAnimationStep = ConnectivityView.animationStepsCount - 1
            case .connectivity:
                await animateIndicator(stepDuration: ConnectivityView.connectivityStepAnimationDuration)
            case .sending:
                await animateIndicator(stepDuration: ConnectivityView.sendingStepAnimationDuration)
                return
            }
        }
    }
    
    private func animateIndicator(stepDuration: Duration) async {
        while (!Task.isCancelled) {
            connectionAnimationStep = (connectionAnimationStep + 1) % ConnectivityView.animationStepsCount
            try? await Task.sleep(for: stepDuration)
        }
    }
    
    private func keyboardSymbolName() -> String {
        if connectivityState == .connected {
            return "keyboard.fill"
        } else {
            return "keyboard"
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
    
    private func animationState() -> AnimationState {
        switch connectivityState {
        case .connecting:
            fallthrough
        case .searching:
            return .connectivity
        case .off:
            return .none
        case .disconnected:
            return .none
        case .connected:
            let passedSinceLastTypeEvent = Duration.seconds(Date.now.timeIntervalSince1970 - typedLastTimeAt.timeIntervalSince1970)
            if passedSinceLastTypeEvent < ConnectivityView.animationAfterTypingDuration {
                return .sending
            } else {
                return .none
            }
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
        ConnectivityView(
            keyEventSignalPublisher: Timer.publish(
                every: 0.1,
                on: RunLoop.main,
                in: RunLoop.Mode.common
            ).map { _ in () }.eraseToAnyPublisher(),
            connectivityState: .connected,
            captureIsOn: Binding.constant(true)
        )
    }
}
#endif
