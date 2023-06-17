//
//  AwaitFirst.swift
//  VirtualKeyboardMessageClient
//
//  Created by Alexander Leontev on 13.06.23.
//

import Combine

extension Publisher {
    
    /// Suspend until the first emission from publisher is made.
    /// Throws `NoElementError` if Publisher has completed before
    /// an emission was made.
    func awaitFirst() async throws -> Output {
        let upstream = self
        
        var cancellables = Set<AnyCancellable>()
        
        var didReceiveElement = false
        
        return try await withCheckedThrowingContinuation { continuation in
            upstream.first().eraseToAnyPublisher().sink { completion in
                switch completion {
                case .failure(let error):
                    continuation.resume(throwing: error)
                    
                case .finished:
                    if !didReceiveElement {
                        continuation.resume(throwing: NoElementError())
                    }
                }
            } receiveValue: { output in
                didReceiveElement = true
                
                continuation.resume(returning: output)
            }.store(in: &cancellables)
        }
    }
}

/// Error that is thrown when Publisher used with `awaitFirst` completes before an emission
/// is made.
struct NoElementError: Error {}
