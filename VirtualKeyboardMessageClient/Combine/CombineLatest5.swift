//
//  CombineLatest5.swift
//  VirtualKeyboardMessageClient
//
//  Created by Alexander Leontev on 13.06.23.
//

import Combine

// This was depressing to write.
// I should've probably stuck with RxSwift, but it's pretty interesting to play with Combine.
/// Same as `combineLatest`, but for 5 arguments.
func combineLatest<
    A: Publisher,
    B: Publisher,
    C: Publisher,
    D: Publisher,
    E: Publisher,
    ReturnType,
    Failure: Error
>(
    _ publisher1: A,
    _ publisher2: B,
    _ publisher3: C,
    _ publisher4: D,
    _ publisher5: E,
    _ transform: @escaping (A.Output, B.Output, C.Output, D.Output, E.Output) -> ReturnType
) -> AnyPublisher<ReturnType, Failure>
    where A.Failure == B.Failure,
          B.Failure == C.Failure,
          C.Failure == D.Failure,
          D.Failure == E.Failure,
          Failure == A.Failure {
        
    return publisher1
        .combineLatest(publisher2)
        .combineLatest(publisher3)
        .map { ($0.0.0, $0.0.1, $0.1) }
        .combineLatest(publisher4)
        .map { ($0.0.0, $0.0.1, $0.0.2, $0.1) }
        .combineLatest(publisher5)
        .map { ($0.0.0, $0.0.1, $0.0.2, $0.0.3, $0.1) }
        .map { (a, b, c, d, e) in
            return transform(a, b, c, d, e)
        }
        .eraseToAnyPublisher()
}
