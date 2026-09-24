//
//  main.swift
//  Project: Thaw
//
//  Copyright (Ice) © 2023–2025 Jordan Baird
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

// Behavioral checks for SimpleSemaphore, compiled together with the actor
// extracted verbatim from MenuBarItemManager.swift. The actor's count is
// private, so permits are counted by probing with short timed waits.
import Foundation

func permits(_ sem: SimpleSemaphore) async -> Int {
    var taken = 0
    while (try? await sem.wait(timeout: .milliseconds(30))) != nil {
        taken += 1
        if taken > 10 {
            break
        }
    }
    for _ in 0 ..< taken {
        await sem.signal()
    }
    return taken
}

var failures = 0
func check(_ name: String, _ ok: Bool, _ detail: String = "") {
    print("\(ok ? "PASS" : "FAIL")  \(name)\(detail.isEmpty ? "" : "  (\(detail))")")
    if !ok {
        failures += 1
    }
}

// 1. Contended hand-offs must not lose permits (signal() used to skip the
//    increment when it woke a waiter).
do {
    let sem = SimpleSemaphore(value: 1)
    let acquired = await withTaskGroup(of: Bool.self) { group in
        for _ in 0 ..< 200 {
            group.addTask {
                guard (try? await sem.wait(timeout: .seconds(5))) != nil else { return false }
                try? await Task.sleep(for: .microseconds(200))
                await sem.signal()
                return true
            }
        }
        return await group.reduce(0) { $0 + ($1 ? 1 : 0) }
    }
    let n = await permits(sem)
    check(
        "all 200 contended hand-offs succeed and keep exactly one permit",
        acquired == 200 && n == 1,
        "acquired=\(acquired) permits=\(n)"
    )
}

// 2. A timed-out wait holds no permit.
do {
    let sem = SimpleSemaphore(value: 1)
    try await sem.wait()
    var timedOut = false
    do { try await sem.wait(timeout: .milliseconds(20)) } catch is SimpleSemaphore.TimeoutError { timedOut = true }
    await sem.signal()
    let n = await permits(sem)
    check("timed-out wait throws TimeoutError and holds nothing", timedOut && n == 1, "timedOut=\(timedOut) permits=\(n)")
}

// 3. Cancelling a timed wait while a signal() races it must not strand the
//    permit (the acquire child could win after the sleep child threw).
do {
    let sem = SimpleSemaphore(value: 1)
    var leaked = 0
    var neverQueued = 0
    for i in 0 ..< 500 {
        try await sem.wait()
        let waiter = Task {
            if (try? await sem.wait(timeout: .seconds(2))) != nil {
                await sem.signal()
            }
        }
        // Only race once the waiter is actually queued; otherwise signal()
        // just restores the permit and the iteration tests nothing.
        let deadline = ContinuousClock.now + .seconds(1)
        while await sem.waiterCount == 0, ContinuousClock.now < deadline {
            await Task.yield()
        }
        if await sem.waiterCount == 0 {
            neverQueued += 1
        }
        try? await Task.sleep(for: .microseconds(i % 7 * 50))
        async let s: Void = sem.signal()
        waiter.cancel()
        await s
        await waiter.value
        let n = await permits(sem)
        if n != 1 {
            leaked += 1
            // Reset to one permit so later iterations stay meaningful.
            if n == 0 {
                await sem.signal()
            }
            for _ in 1 ..< max(n, 1) {
                try await sem.wait()
            }
        }
    }
    check(
        "cancel racing signal never strands a permit (500 runs)",
        leaked == 0 && neverQueued == 0,
        "bad runs=\(leaked) never queued=\(neverQueued)"
    )
}

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
