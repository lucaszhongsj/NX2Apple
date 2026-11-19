import Testing
@testable import ShellUI

@Suite struct PortraitScrollDecorationTests {
    @Test func foldedHeroPullsDownOnlyPastTheTop() {
        #expect(PortraitScrollDecoration.value(offset: -32, includesHero: true) == .pullDown(32))
        #expect(PortraitScrollDecoration.value(offset: 0, includesHero: true) == .pullDown(0))
        #expect(PortraitScrollDecoration.value(offset: 80, includesHero: true) == .pullDown(0))
    }

    @Test func expandedScrollDecorationIsIndependentOfOffset() {
        #expect(PortraitScrollDecoration.value(offset: -80, includesHero: false) == .inactive)
        #expect(PortraitScrollDecoration.value(offset: 80, includesHero: false) == .inactive)
    }

    @Test func scrollingDoesNotKeepInvalidatingDecoration() {
        let offsets = (0...1_000).map { Double($0) }
        let values = offsets.map { PortraitScrollDecoration.value(offset: $0, includesHero: false) }
        #expect(zip(values, values.dropFirst()).allSatisfy { $0 == $1 })
    }
}
