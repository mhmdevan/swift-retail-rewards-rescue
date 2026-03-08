import XCTest

final class AccessibilityAuditUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testLoginScreenAccessibilityIdentifiers() {
        XCTAssertTrue(app.textFields["login_email"].exists)
        XCTAssertTrue(app.secureTextFields["login_password"].exists)
        XCTAssertTrue(app.switches["login_biometrics_toggle"].exists)
        XCTAssertTrue(app.buttons["login_submit"].exists)
    }

    func testCoreListsExposeStableAccessibilityIdentifiers() {
        app.buttons["login_submit"].tap()
        XCTAssertTrue(app.tables["offers_table"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Saved"].tap()
        XCTAssertTrue(app.tables["saved_offers_table"].waitForExistence(timeout: 3))

        app.tabBars.buttons["Inbox"].tap()
        XCTAssertTrue(app.tables["inbox_table"].waitForExistence(timeout: 3))
    }
}
