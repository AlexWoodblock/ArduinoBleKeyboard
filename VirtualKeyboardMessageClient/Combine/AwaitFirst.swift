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
        // unfortunately, we can't simply clear cancellables
        // due to their concurrent usage.
        // Instead, we resort to a little trickery - this subject emission will signal the end of
        // original upstream publisher, and we can safely signal it inside of cancellation handler
        let forceCompletionSubject = PassthroughSubject<Void, Never>()
        
        let upstream = self
        
        var cancellables = Set<AnyCancellable>()
        
        var didReceiveElement = false
        
        return try await withTaskCancellationHandler {
            return try await withCheckedThrowingContinuation { continuation in
                upstream
                    .prefix(untilOutputFrom: forceCompletionSubject)
                    .first()
                    .eraseToAnyPublisher()
                    .sink { completion in
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
        } onCancel: {
            forceCompletionSubject.send(())
        }
    }
}

/// Error that is thrown when Publisher used with `awaitFirst` completes before an emission
/// is made.
struct NoElementError: Error {}
