import Testing
@testable import DesignSystem

@Test func spacingTokensAreOrdered() {
    #expect(DSSpacing.xxs < DSSpacing.xs)
    #expect(DSSpacing.xs < DSSpacing.sm)
    #expect(DSSpacing.sm < DSSpacing.md)
    #expect(DSSpacing.md < DSSpacing.lg)
    #expect(DSSpacing.lg < DSSpacing.xl)
}
