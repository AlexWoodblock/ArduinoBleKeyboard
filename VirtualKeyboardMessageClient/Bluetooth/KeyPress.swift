//
//  KeyPress.swift
//  VirtualKeyboardMessageClient
//
//  Created by Alexander Leontev on 13.06.23.
//
import Foundation
import Cocoa

/// Key press BLE-serializable description.
struct KeyPress {
    
    private static let ctrlModifier: UInt16 = 0x01
    private static let shiftModifier: UInt16 = 0x02
    
    private let keyCode: UInt16
    private let keyModifier: UInt16
    
    /// Creates an instance of `KeyPress` from `NSEvent`.
    /// `NSEvent` should be a keypress event, otherwise trash data may be sent.
    init(event: NSEvent) {
        keyCode = UInt16(virtualKeyCodeToHIDKeyCode(vKeyCode: Int(event.keyCode)))
        
        var resultingModifier: UInt16 = 0
        
        if event.modifierFlags.contains(.shift) {
            resultingModifier = resultingModifier | KeyPress.shiftModifier
        }
        
        if event.modifierFlags.contains(.control) {
            resultingModifier = resultingModifier | KeyPress.ctrlModifier
        }
        
        keyModifier = resultingModifier
    }
    
    /// Create `Data` to be send to BLE device.
    func data() -> Data {
        var data = Data()
        
        let keyCodeContent = [
            UInt8(keyCode >> 8),
            UInt8(keyCode),
        ]
        data.append(contentsOf: keyCodeContent)
        
        let keyModifierContent = [
            UInt8(keyModifier >> 8),
            UInt8(keyModifier),
        ]
        data.append(contentsOf: keyModifierContent)
        
        return data
    }
}
