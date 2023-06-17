//
//  SizeReader.swift
//  VirtualKeyboardMessageClient
//
//  Created by Alexander Leontev on 17.06.23.
//

import SwiftUI

extension View {
    
    func sizeReader(_ reader: @escaping (CGFloat, CGFloat) -> Void) -> some View {
        return background(
            GeometryReader { proxy in
                reader(proxy.size.width, proxy.size.height)
                return Color.clear.hidden()
            }
        )
    }
    
}
