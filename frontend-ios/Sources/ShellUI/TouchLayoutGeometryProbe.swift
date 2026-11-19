import CoreGraphics
import Foundation
#if os(iOS)
import SwiftUI
import UIKit
#endif

/// UIKit measurements for the fullscreen editor's own view hierarchy.
struct TouchLayoutGeometrySnapshot: Equatable {
    var bounds: CGRect
    var safeAreaInsets: PadScreen.Insets

    var screen: PadScreen { PadScreen(size: bounds.size, insets: safeAreaInsets) }
}

#if os(iOS)
/// A transparent, non-interactive UIView placed in the editor's full-screen content.
/// UIKit supplies the same view-local bounds and safe areas that the game root passes to its layout engine.
@MainActor
struct TouchLayoutGeometryProbe: UIViewRepresentable {
    var onChange: (TouchLayoutGeometrySnapshot) -> Void

    func makeUIView(context: Context) -> TouchLayoutGeometryProbeView {
        let view = TouchLayoutGeometryProbeView()
        view.onChange = onChange
        return view
    }

    func updateUIView(_ uiView: TouchLayoutGeometryProbeView, context: Context) {
        uiView.onChange = onChange
        uiView.setNeedsLayout()
    }
}

@MainActor
final class TouchLayoutGeometryProbeView: UIView {
    var onChange: ((TouchLayoutGeometrySnapshot) -> Void)?
    private var lastSnapshot: TouchLayoutGeometrySnapshot?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false
        accessibilityElementsHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        emitSnapshot()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        setNeedsLayout()
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        setNeedsLayout()
    }

    private func emitSnapshot() {
        let bounds = CGRect(origin: .zero, size: self.bounds.size)
        guard !bounds.isEmpty else { return }
        let safe = safeAreaInsets
        let insets = PadScreen.Insets(top: safe.top, left: safe.left, bottom: safe.bottom, right: safe.right)
        let snapshot = TouchLayoutGeometrySnapshot(bounds: bounds, safeAreaInsets: insets)
        guard snapshot != lastSnapshot else { return }
        lastSnapshot = snapshot
        Task { @MainActor [weak self] in self?.onChange?(snapshot) }
    }
}
#endif
