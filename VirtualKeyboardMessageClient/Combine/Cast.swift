//
//  Cast.swift
//  VirtualKeyboardMessageClient
//
//  Created by Alexander Leontev on 13.06.23.
//

import Combine

extension Publisher {
    
    /// Unconditionally cast emissions to a given type.
    func cast<NewOutputType>() -> AnyPublisher<NewOutputType, Failure> {
        return map { $0 as! NewOutputType }.eraseToAnyPublisher()
    }
}
