//
//  KeyEventMonitoringInteractor.swift
//  VirtualKeyboardMessageClient
//
//  Created by Alexander Leontev on 13.06.23.
//

import Foundation
import Cocoa

/// Interactor to capture keyboard events for the focused window.
class KeyEventMonitoringInteractor {
    
    /// Callback for captured events. Will be called for each `keyDown` event.
    var onCapturedEvent: ((NSEvent) -> Void)? = nil
    
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
                
                self?.onCapturedEvent?(event)
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
