//
//  AppDelegate.swift
//  VirtualKeyboardMessageClient
//
//  Created by Alexander Leontev on 17.06.23.
//

import Foundation
import AppKit

/// App delegate - implemented only because of applicationShouldTerminateAfterLastWindowClosed.
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
}
