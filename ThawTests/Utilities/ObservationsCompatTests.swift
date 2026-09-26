//
//  ObservationsCompatTests.swift
//  Project: Thaw
//
//  Copyright (Ice) © 2023–2025 Jordan Baird
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import Observation
import Testing
@testable import Thaw

/// Covers `ObservationsCompat`, the stand-in for `Observations` that also
/// runs on macOS 15. Both of its backends must satisfy the same contract.
@MainActor
struct ObservationsCompatTests {
    @Observable
    final class Model {
        var value = 0
    }

    /// Both backends must satisfy the same contract: `.automatic` is
    /// `Observations` on macOS 26+, `.tracking` is the macOS 15 fallback.
    enum Backend: CaseIterable {
        case automatic
        case tracking

        func observe(_ emit: @escaping @MainActor () -> Int) -> ObservationsCompat<Int> {
            switch self {
            case .automatic: ObservationsCompat(emit)
            case .tracking: .tracking(emit)
            }
        }
    }

    @Test(arguments: Backend.allCases)
    func emitsCurrentValueFirst(backend: Backend) async {
        let model = Model()
        model.value = 7
        var iterator = backend.observe { model.value }.makeAsyncIterator()
        #expect(await iterator.next() == 7)
    }

    @Test(arguments: Backend.allCases)
    func emitsNewValueAfterChange(backend: Backend) async {
        let model = Model()
        var iterator = backend.observe { model.value }.makeAsyncIterator()
        #expect(await iterator.next() == 0)

        Task { model.value = 1 }
        #expect(await iterator.next() == 1)
    }

    @Test(arguments: Backend.allCases)
    func finishesWhenIteratingTaskIsCancelled(backend: Backend) async {
        let model = Model()
        let (seen, reportSeen) = AsyncStream.makeStream(of: Int.self)
        let task = Task {
            var received = [Int]()
            for await value in backend.observe({ model.value }) {
                received.append(value)
                reportSeen.yield(value)
            }
            return received
        }
        // Cancel only once the loop has the first value and waits for a change.
        var seenIterator = seen.makeAsyncIterator()
        _ = await seenIterator.next()
        task.cancel()
        #expect(await task.value == [0])
    }

    @Test(arguments: Backend.allCases)
    func tracksPropertiesReadAfterAChange(backend: Backend) async {
        let model = Model()
        let other = Model()
        var iterator = backend.observe { model.value + other.value }.makeAsyncIterator()
        #expect(await iterator.next() == 0)
        Task { model.value = 1 }
        #expect(await iterator.next() == 1)
        Task { other.value = 10 }
        #expect(await iterator.next() == 11)
    }
}
