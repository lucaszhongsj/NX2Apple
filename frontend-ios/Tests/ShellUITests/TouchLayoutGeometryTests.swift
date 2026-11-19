import CoreGraphics
import Foundation
import Testing
@testable import ShellUI

@Suite struct TouchLayoutGeometryTests {
    @MainActor @Test func editorTitlesFollowTheLiveOrientation() {
        let landscape = PadScreen(size: CGSize(width: 951, height: 669), insets: .init())
        let portrait = PadScreen(size: CGSize(width: 669, height: 951), insets: .init())
        #expect(TouchLayoutEditorView.layoutTitle(screen: landscape) == ShellStrings.text("Landscape"))
        #expect(TouchLayoutEditorView.layoutTitle(screen: portrait) == ShellStrings.text("Portrait"))
    }
    @Test func aLandscapePhoneKeepsItsActualAsymmetricSafeInsets() {
        let snapshot = TouchLayoutGeometrySnapshot(
            bounds: CGRect(x: 0, y: 0, width: 956, height: 440),
            safeAreaInsets: .init(top: 0, left: 58, bottom: 0, right: 21)
        )

        #expect(snapshot.screen.size == CGSize(width: 956, height: 440))
        #expect(snapshot.screen.insets == PadScreen.Insets(top: 0, left: 58, bottom: 0, right: 21))
    }

    @MainActor @Test func onlyOrdinaryPhonePortraitUsesTheRotatedFallback() {
        let portrait = TouchLayoutGeometrySnapshot(
            bounds: CGRect(x: 0, y: 0, width: 402, height: 874),
            safeAreaInsets: .init(top: 62, left: 0, bottom: 34, right: 0)
        )
        let context = TouchLayoutEditorView.editorContext(geometry: portrait)
        #expect(context.phonePortraitFallback)
        #expect(context.screen.size == CGSize(width: 874, height: 402))

        let landscape = TouchLayoutGeometrySnapshot(
            bounds: CGRect(x: 0, y: 0, width: 956, height: 440),
            safeAreaInsets: .init(top: 0, left: 58, bottom: 0, right: 21)
        )
        let live = TouchLayoutEditorView.editorContext(geometry: landscape)
        #expect(!live.phonePortraitFallback)
        #expect(live.screen.insets == landscape.safeAreaInsets)
    }
}
