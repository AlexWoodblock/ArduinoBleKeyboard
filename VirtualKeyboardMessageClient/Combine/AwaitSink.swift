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
        let upstream = self
        
        // unfortunately, we can't simply clear cancellables
        // due to their concurrent usage.
        // Instead, we resort to a little trickery - this subject emission will signal the end of
        // original upstream publisher, and we can safely signal it inside of cancellation handler
        let forceCompletionSubject = PassthroughSubject<Void, Never>()
        
        var cancellables = Set<AnyCancellable>()
        
        // return is only needed here because otherwise Swift wouldn't
        // understand it's Void
        return try await withTaskCancellationHandler {
            return try await withCheckedThrowingContinuation { continuation in
                upstream
                    .prefix(untilOutputFrom: forceCompletionSubject)
                    .sink { completion in
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
        } onCancel: {
            forceCompletionSubject.send(())
        }
    }
    
}
