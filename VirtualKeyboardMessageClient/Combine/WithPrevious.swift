//
//  WithPrevious.swift
//  VirtualKeyboardMessageClient
//
//  Created by Alexander Leontev on 17.06.23.
//

import Combine

extension Publisher {
    
    /// Emit pairs of current and previous emissions.
    /// Will not emit anything on first emission.
    func withPrevious() -> AnyPublisher<(Output, Output), Failure> {
        return scan([Output]()) { history, output in
            var newHistory = history
            newHistory.append(output)
            newHistory.removeFirst(Swift.max(0, newHistory.count - 2))
            return newHistory
        }.filter { history in
            history.count > 1
        }.map { history in
            (history[0], history[1])
        }.eraseToAnyPublisher()
    }
    
}
