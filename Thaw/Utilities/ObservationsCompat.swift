//
//  ObservationsCompat.swift
//  Project: Thaw
//
//  Copyright (Ice) © 2023–2025 Jordan Baird
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import Observation
import Synchronization

/// A stand-in for `Observations` (macOS 26+) that also runs on macOS 15.
///
/// Emits the closure's current value first, then a fresh value after each
/// change to the observable properties it read. Iteration ends when the
/// iterating task is cancelled.
nonisolated struct ObservationsCompat<Element: Sendable>: AsyncSequence, Sendable {
    private let emit: @MainActor () -> Element

    init(_ emit: @escaping @MainActor () -> Element) {
        self.emit = emit
    }

    func makeAsyncIterator() -> Iterator {
        if #available(macOS 26.0, *) {
            Iterator(native: Observations(emit).makeAsyncIterator())
        } else {
            Iterator(emit: emit)
        }
    }

    nonisolated struct Iterator: AsyncIteratorProtocol {
        /// `Observations`' iterator on macOS 26+.
        private var native: (any AsyncIteratorProtocol<Element, Never>)?
        /// The `withObservationTracking` fallback for earlier releases.
        private let emit: (@MainActor () -> Element)?
        private var pendingChange: ChangeSignal?

        @available(macOS 26.0, *)
        fileprivate init(native: Observations<Element, Never>.Iterator) {
            self.native = native
            self.emit = nil
        }

        fileprivate init(emit: @escaping @MainActor () -> Element) {
            self.native = nil
            self.emit = emit
        }

        mutating func next() async -> Element? {
            if var native {
                let value = await native.next(isolation: #isolation)
                self.native = native
                return value
            }
            guard let emit else { return nil }
            if let pendingChange {
                await pendingChange.wait()
            }
            guard !Task.isCancelled else { return nil }
            let signal = ChangeSignal()
            pendingChange = signal
            return await Self.track(emit, firing: signal)
        }

        @MainActor
        private static func track(_ emit: @MainActor () -> Element, firing signal: ChangeSignal) -> Element {
            withObservationTracking(emit) { signal.fire() }
        }
    }
}

/// A one-shot signal from `withObservationTracking`'s `onChange`, which may
/// fire before anyone waits on it and on any thread.
private nonisolated final class ChangeSignal: Sendable {
    private enum State {
        case idle
        case fired
        case waiting(CheckedContinuation<Void, Never>)
    }

    private let state = Mutex(State.idle)

    func fire() {
        let waiter = state.withLock { state -> CheckedContinuation<Void, Never>? in
            if case let .waiting(continuation) = state {
                state = .fired
                return continuation
            }
            state = .fired
            return nil
        }
        waiter?.resume()
    }

    func wait() async {
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                let resumeNow = state.withLock { state -> Bool in
                    if case .fired = state { return true }
                    state = .waiting(continuation)
                    return false
                }
                if resumeNow { continuation.resume() }
            }
        } onCancel: {
            fire()
        }
    }
}
