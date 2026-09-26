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
///
/// A badge dropped at the section's default slot must follow that end, not
/// the item next to it: anchoring it to a neighbor made it drift into the
/// middle of the section when a sort moved that neighbor.
@Suite("New Items badge drop")
struct NewItemsBadgeDropTests {
    typealias Placement = MenuBarItemManager.NewItemsPlacement

    struct Drop: CustomTestStringConvertible, Sendable {
        let name: String
        let leftAnchor: String?
        let rightAnchor: String?
        let defaultSlotIsAtStart: Bool
        let expected: Placement

        var testDescription: String { name }
    }

    static let drops: [Drop] = [
        Drop(
            name: "default end slot keeps the section default",
            leftAnchor: "com.vibeproxy.app:Item-0", rightAnchor: nil, defaultSlotIsAtStart: false,
            expected: Placement(sectionKey: "hidden", anchorIdentifier: nil, relation: .sectionDefault)
        ),
        Drop(
            name: "default start slot keeps the section default",
            leftAnchor: nil, rightAnchor: "com.example.clock", defaultSlotIsAtStart: true,
            expected: Placement(sectionKey: "hidden", anchorIdentifier: nil, relation: .sectionDefault)
        ),
        Drop(
            name: "between items anchors left of the right neighbor",
            leftAnchor: "com.example.a", rightAnchor: "com.example.b", defaultSlotIsAtStart: false,
            expected: Placement(sectionKey: "hidden", anchorIdentifier: "com.example.b", relation: .leftOfAnchor)
        ),
        Drop(
            name: "non-default end anchors right of the left neighbor",
            leftAnchor: "com.example.a", rightAnchor: nil, defaultSlotIsAtStart: true,
            expected: Placement(sectionKey: "hidden", anchorIdentifier: "com.example.a", relation: .rightOfAnchor)
        ),
    ]

    @Test("A badge drop becomes the expected placement", arguments: drops)
    func placement(for drop: Drop) {
        let placement = MenuBarItemManager.placementForNewItemsBadge(
            sectionKey: "hidden",
            leftAnchor: drop.leftAnchor,
            rightAnchor: drop.rightAnchor,
            defaultSlotIsAtStart: drop.defaultSlotIsAtStart
        )
        #expect(placement == drop.expected)
    }
}
