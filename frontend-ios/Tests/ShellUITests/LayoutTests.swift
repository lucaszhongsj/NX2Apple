import XCTest
import SwiftUI
@testable import ShellUI

final class LayoutTests: XCTestCase {
    private func layout(_ width: CGFloat, _ height: CGFloat, large: Bool = false) -> ShellLayout {
        ShellLayout.resolve(CGSize(width: width, height: height), accessibilityText: large)
    }
    func testPhone() {
        XCTAssertEqual(layout(402, 874), .column)
        XCTAssertEqual(layout(874, 402), .coverFlow(regular: false))
    }
    func testPad() {
        XCTAssertEqual(layout(834, 1194), .grid)
        XCTAssertEqual(layout(1194, 834), .coverFlow(regular: true))
        // Split View and narrow Stage Manager windows are compact.
        XCTAssertEqual(layout(507, 834), .column)
        XCTAssertEqual(layout(375, 688), .column)
    }
    /// Windows of other large sizes: the same rules as above, on sample sizes the views do not know about.
    func testLargeWindows() {
        XCTAssertEqual(layout(375, 525), .column)
        XCTAssertEqual(layout(525, 375), .coverFlow(regular: false))
        XCTAssertEqual(layout(626, 890), .grid)
        XCTAssertEqual(layout(890, 626), .coverFlow(regular: true))
        XCTAssertEqual(layout(669, 951), .grid)
        XCTAssertEqual(layout(951, 669), .coverFlow(regular: true))
    }
    /// A nearly square window keeps the upright library. Cover Flow needs clearly more width than height.
    func testSquareWindowKeepsTwoPanes() {
        XCTAssertEqual(layout(800, 760), .grid)
    }
    func testAccessibilityTextUsesOneColumn() {
        XCTAssertEqual(layout(834, 1194, large: true), .column)
    }

}

final class ChoicePresentationTests: XCTestCase {
    private func resolve(_ labels: [String], _ width: CGFloat?, scale: CGFloat = 1) -> ChoicePresentation {
        ChoicePresentation.resolve(labels: labels, width: width, textScale: scale)
    }
    func testFewShortLabelsAreSegmented() {
        XCTAssertEqual(resolve(["Handheld", "Docked"], 400), .segmented)
        XCTAssertEqual(resolve(["30 fps", "60 fps"], 300), .segmented)
        XCTAssertEqual(resolve(["Off", "Low", "Medium", "High"], 420), .segmented)
    }
    func testManyOptionsAreAListWhateverTheWidth() {
        let five = ["A", "B", "C", "D", "E"]
        XCTAssertEqual(resolve(five, 2000), .list)
        XCTAssertEqual(resolve(five, nil), .list)
        let languages = Array(repeating: "American English", count: 15)
        XCTAssertEqual(resolve(languages, 600), .list)
    }
    func testSingleOrNoOptionIsAList() {
        XCTAssertEqual(resolve(["Only"], 400), .list)
        XCTAssertEqual(resolve([], 400), .list)
    }
    func testLongLabelsDoNotFitTheirSegment() {
        let labels = ["Latin American Spanish", "Brazilian Portuguese"]
        XCTAssertEqual(resolve(labels, 300), .list)
        XCTAssertEqual(resolve(labels, 640), .segmented)
    }
    func testNarrowWidthAndLargerTextTurnSegmentsIntoAList() {
        let labels = ["Handheld", "Docked"]
        XCTAssertEqual(resolve(labels, 400), .segmented)
        XCTAssertEqual(resolve(labels, 150), .list)
        XCTAssertEqual(resolve(["Standard", "Performance", "Quality"], 360), .segmented)
        XCTAssertEqual(resolve(["Standard", "Performance", "Quality"], 360, scale: 1.6), .list)
    }
    func testWidthUnknownDecidesByCountOnly() {
        XCTAssertEqual(resolve(["Handheld", "Docked"], nil), .segmented)
    }
    func testTextScaleGrowsWithDynamicType() {
        XCTAssertEqual(ChoicePresentation.textScale(.large), 1)
        XCTAssertLessThan(ChoicePresentation.textScale(.small), 1)
        XCTAssertGreaterThan(ChoicePresentation.textScale(.accessibility3), ChoicePresentation.textScale(.xxxLarge))
    }
}

@MainActor final class GameLaunchActionLayoutTests: XCTestCase {
    func testCollapseStopsAtTheCompactHeaderAndIgnoresOverscroll() {
        XCTAssertEqual(ShellLayout.collapseProgress(expanded: 400, minimum: 240, travel: -20), 0)
        XCTAssertEqual(ShellLayout.collapseProgress(expanded: 400, minimum: 240, travel: 80), 0.5)
        XCTAssertEqual(ShellLayout.collapseProgress(expanded: 400, minimum: 240, travel: 1000), 1)
        XCTAssertEqual(ShellLayout.collapseProgress(expanded: 200, minimum: 240, travel: 80), 1)
    }
}
