//
//  KeyEventMonitoringInteractor.swift
//  VirtualKeyboardMessageClient
//
//  Created by Alexander Leontev on 13.06.23.
//

import Combine
import Foundation
import Cocoa

/// Interactor to capture keyboard events for the focused window.
class KeyEventMonitoringInteractor {
    
    var capturedEventPublisher: AnyPublisher<NSEvent, Never> {
        return capturedEventSubject.eraseToAnyPublisher()
    }
    
    private let capturedEventSubject = PassthroughSubject<NSEvent, Never>()
    
    private var monitorHandle: Any? = nil
    
    /// Enable or disable keyboard presses capture.
    func setCapture(enabled: Bool) {
        if (enabled) {
            guard monitorHandle == nil else {
                return
            }
            
            monitorHandle = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard event.type == .keyDown else {
                    return event
                }
                
                self?.capturedEventSubject.send(event)
                return nil
            }
        } else {
            guard let monitorHandle = monitorHandle else {
                return
            }
            
            NSEvent.removeMonitor(monitorHandle)
            self.monitorHandle = nil
        }
    }
    
}
