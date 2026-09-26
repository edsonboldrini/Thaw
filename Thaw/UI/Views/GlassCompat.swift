//
//  GlassCompat.swift
//  Project: Thaw
//
//  Copyright (Ice) © 2023–2025 Jordan Baird
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import AppKit
import SwiftUI

// Liquid Glass is macOS 26+. These stand-ins use it there and fall back to
// materials and bordered styles on macOS 15, so views need no availability
// checks of their own.

/// The glass variants Thaw uses.
enum GlassCompatStyle {
    case regular
    case interactive
    case clear(tint: Color)
}

extension View {
    /// `glassEffect(_:in:)` on macOS 26+, a material background before.
    @ViewBuilder
    func glassEffectCompat(_ style: GlassCompatStyle = .regular, in shape: some Shape) -> some View {
        if #available(macOS 26.0, *) {
            switch style {
            case .regular: glassEffect(.regular, in: shape)
            case .interactive: glassEffect(.regular.interactive(), in: shape)
            case let .clear(tint): glassEffect(.clear.tint(tint), in: shape)
            }
        } else {
            switch style {
            case .regular, .interactive: background(.regularMaterial, in: shape)
            case let .clear(tint): background(tint, in: shape)
            }
        }
    }

    /// `.glass` / `.glassProminent` on macOS 26+, `.bordered` /
    /// `.borderedProminent` before.
    @ViewBuilder
    func glassButtonStyleCompat(prominent: Bool = false) -> some View {
        if #available(macOS 26.0, *) {
            if prominent { buttonStyle(.glassProminent) } else { buttonStyle(.glass) }
        } else {
            if prominent { buttonStyle(.borderedProminent) } else { buttonStyle(.bordered) }
        }
    }

    /// `scrollEdgeEffectStyle(_:for:)` on macOS 26+; no edge effect before.
    @ViewBuilder
    func scrollEdgeEffectCompat(soft: Bool = false, for edges: Edge.Set) -> some View {
        if #available(macOS 26.0, *) {
            scrollEdgeEffectStyle(soft ? .soft : .automatic, for: edges)
        } else {
            self
        }
    }

    /// `safeAreaBar(edge:spacing:content:)` on macOS 26+,
    /// `safeAreaInset(edge:spacing:content:)` before.
    @ViewBuilder
    func safeAreaBarCompat(
        edge: VerticalEdge,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> some View
    ) -> some View {
        if #available(macOS 26.0, *) {
            safeAreaBar(edge: edge, spacing: spacing, content: content)
        } else {
            safeAreaInset(edge: edge, spacing: spacing, content: content)
        }
    }
}

/// `GlassEffectContainer` on macOS 26+, its content alone before.
struct GlassEffectContainerCompat<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer { content }
        } else {
            content
        }
    }
}

/// `NSGlassEffectView` on macOS 26+, `NSVisualEffectView` before.
///
/// Exposes the subset of `NSGlassEffectView` Thaw uses: `style`,
/// `cornerRadius` and `contentView`.
final class GlassEffectViewCompat: NSView {
    private let effectView: NSView

    var style: MenuBarGlassStyle = .regular {
        didSet { applyStyle() }
    }

    var cornerRadius: CGFloat = 0 {
        didSet { applyCornerRadius() }
    }

    var contentView: NSView? {
        didSet {
            guard contentView !== oldValue else { return }
            if #available(macOS 26.0, *), let glass = effectView as? NSGlassEffectView {
                glass.contentView = contentView
            } else {
                oldValue?.removeFromSuperview()
                if let contentView {
                    embed(contentView, in: effectView)
                }
            }
        }
    }

    init() {
        if #available(macOS 26.0, *) {
            effectView = NSGlassEffectView()
        } else {
            let visualEffect = NSVisualEffectView()
            visualEffect.blendingMode = .behindWindow
            visualEffect.state = .active
            effectView = visualEffect
        }
        super.init(frame: .zero)
        wantsLayer = true
        embed(effectView, in: self)
        applyStyle()
        applyCornerRadius()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func applyStyle() {
        if #available(macOS 26.0, *), let glass = effectView as? NSGlassEffectView {
            glass.style = style.nsGlassStyle
        } else if let visualEffect = effectView as? NSVisualEffectView {
            visualEffect.material = switch style {
            case .regular: .hudWindow
            case .clear: .underWindowBackground
            }
        }
    }

    private func applyCornerRadius() {
        if #available(macOS 26.0, *), let glass = effectView as? NSGlassEffectView {
            glass.cornerRadius = cornerRadius
        } else {
            effectView.wantsLayer = true
            effectView.layer?.cornerRadius = cornerRadius
            effectView.layer?.masksToBounds = cornerRadius > 0
        }
    }

    private func embed(_ view: NSView, in container: NSView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
    }
}
