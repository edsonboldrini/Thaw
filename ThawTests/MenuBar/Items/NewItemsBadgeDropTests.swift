//
//  NewItemsBadgeDropTests.swift
//  Project: Thaw
//
//  Copyright (Ice) © 2023–2025 Jordan Baird
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import Testing
@testable import Thaw

/// Covers `MenuBarItemManager.placementForNewItemsBadge(sectionKey:leftAnchor:rightAnchor:defaultSlotIsAtStart:)`,
/// which turns the New Items badge's drop position into a placement.
@Suite("New Items badge drop")
struct NewItemsBadgeDropTests {
    typealias Placement = MenuBarItemManager.NewItemsPlacement

    /// A badge dropped at the section's default end must follow that end,
    /// not the item next to it: anchoring it to a neighbor made it drift
    /// into the middle of the section when a sort moved that neighbor.
    @Test("A badge on the default end slot keeps the section default")
    func defaultEndSlotIsSectionDefault() {
        let placement = MenuBarItemManager.placementForNewItemsBadge(
            sectionKey: "hidden",
            leftAnchor: "com.vibeproxy.app:Item-0",
            rightAnchor: nil,
            defaultSlotIsAtStart: false
        )
        #expect(placement == Placement(sectionKey: "hidden", anchorIdentifier: nil, relation: .sectionDefault))
    }

    @Test("A badge on the default start slot keeps the section default")
    func defaultStartSlotIsSectionDefault() {
        let placement = MenuBarItemManager.placementForNewItemsBadge(
            sectionKey: "visible",
            leftAnchor: nil,
            rightAnchor: "com.example.clock",
            defaultSlotIsAtStart: true
        )
        #expect(placement.relation == .sectionDefault)
    }

    @Test("A badge between items anchors left of its right neighbor")
    func betweenItemsAnchorsToRightNeighbor() {
        let placement = MenuBarItemManager.placementForNewItemsBadge(
            sectionKey: "hidden",
            leftAnchor: "com.example.a",
            rightAnchor: "com.example.b",
            defaultSlotIsAtStart: false
        )
        #expect(placement == Placement(sectionKey: "hidden", anchorIdentifier: "com.example.b", relation: .leftOfAnchor))
    }

    @Test("A badge on the non-default end anchors right of its left neighbor")
    func oppositeEndAnchorsToLeftNeighbor() {
        let placement = MenuBarItemManager.placementForNewItemsBadge(
            sectionKey: "hidden",
            leftAnchor: "com.example.a",
            rightAnchor: nil,
            defaultSlotIsAtStart: true
        )
        #expect(placement == Placement(sectionKey: "hidden", anchorIdentifier: "com.example.a", relation: .rightOfAnchor))
    }
}
