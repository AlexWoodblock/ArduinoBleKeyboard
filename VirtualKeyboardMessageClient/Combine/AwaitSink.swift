//
//  AwaitSink.swift
//  VirtualKeyboardMessageClient
//
//  Created by Alexander Leontev on 13.06.23.
//

import Combine

extension Publisher {
    
    /// Applies `sink` function to this Publisher, and suspends until
    /// the Publisher completes.
    func awaitSink(receiveValue: @escaping (Output) -> Void) async throws {
        var cancellables = Set<AnyCancellable>()
        
        // return is only needed here because otherwise Swift wouldn't
        // understand it's Void
        return try await withCheckedThrowingContinuation { continuation in
            sink { completion in
                switch completion {
                case .failure(let error):
                    continuation.resume(throwing: error)
                case .finished:
                    continuation.resume()
                }
            } receiveValue: { output in
                receiveValue(output)
            }.store(in: &cancellables)

        }
    }
    
}
