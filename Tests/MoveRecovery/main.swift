//
//  main.swift
//  Project: Thaw
//
//  Copyright (Ice) © 2023–2025 Jordan Baird
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import CoreGraphics
import Foundation

var failures = 0
func check(_ name: String, _ ok: Bool, _ detail: String = "") {
    print("\(ok ? "PASS" : "FAIL")  \(name)\(detail.isEmpty ? "" : "  (\(detail))")")
    if !ok {
        failures += 1
    }
}

// Seam 1: where a late off-screen mouse-down leaves the cursor.
// Expected points come from the display geometry, not from the code: the
// window server keeps the cursor on a display, so (20000, 20000) lands on
// the bottom-right pixel of the display nearest to it.
do {
    let builtIn = CGRect(x: 0, y: 0, width: 1512, height: 982)
    // An external display above and to the left, as on the reporting Mac.
    let externalAboveLeft = CGRect(x: -211, y: -1080, width: 1920, height: 1080)
    let externalRight = CGRect(x: 1512, y: 0, width: 2560, height: 1440)

    check(
        "single display: its bottom-right pixel is the clamp point",
        isAtOffscreenClamp(CGPoint(x: 1511, y: 981), displays: [builtIn])
    )
    check(
        "external above-left: still the built-in bottom-right pixel",
        isAtOffscreenClamp(CGPoint(x: 1511, y: 981), displays: [builtIn, externalAboveLeft])
    )
    check(
        "external above-left: the union's corner is not a clamp point",
        !isAtOffscreenClamp(CGPoint(x: 1708, y: 981), displays: [builtIn, externalAboveLeft])
    )
    check(
        "external to the right: the clamp moves to that display's corner",
        isAtOffscreenClamp(CGPoint(x: 4071, y: 1439), displays: [builtIn, externalRight])
            && !isAtOffscreenClamp(CGPoint(x: 1511, y: 981), displays: [builtIn, externalRight])
    )
    check(
        "a point a few pixels away from the corner is not the clamp point",
        !isAtOffscreenClamp(CGPoint(x: 1500, y: 970), displays: [builtIn])
    )
    check(
        "the middle of the screen is not the clamp point",
        !isAtOffscreenClamp(CGPoint(x: 756, y: 491), displays: [builtIn])
    )
}

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
