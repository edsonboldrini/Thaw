//
//  OwnerPIDEnumerationTests.swift
//  Project: Thaw
//
//  Copyright (Ice) © 2023–2025 Jordan Baird
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import CoreGraphics
import Testing
@testable import Thaw

/// Covers `MenuBarItem.makeItemsUsingOwnerPIDs(from:)`, the enumeration used
/// before macOS 26, where each status item window is still owned by the app
/// that created it.
@MainActor
struct OwnerPIDEnumerationTests {
    private func itemWindow(_ windowID: CGWindowID, pid: pid_t, title: String) -> WindowInfo {
        WindowInfo(
            windowID: windowID,
            ownerPID: pid,
            bounds: CGRect(x: 100, y: 0, width: 24, height: 24),
            layer: 25,
            title: title,
            ownerName: "Owner"
        )
    }

    @Test
    func sourcePIDIsTheWindowOwner() {
        let snapshot = MenuBarItem.makeItemsUsingOwnerPIDs(from: [
            itemWindow(10, pid: 501, title: "Clock"),
            itemWindow(11, pid: 777, title: "Weather"),
        ])
        #expect(snapshot.items.map(\.sourcePID) == [501, 777])
    }

    @Test
    func sameTitleItemsGetInstanceIndicesInWindowIDOrder() {
        let snapshot = MenuBarItem.makeItemsUsingOwnerPIDs(from: [
            itemWindow(42, pid: 900, title: "OneDrive"),
            itemWindow(41, pid: 900, title: "OneDrive"),
        ])
        #expect(snapshot.items.map(\.windowID) == [42, 41])
        #expect(snapshot.items.map(\.tag.instanceIndex) == [1, 0])
    }
}
