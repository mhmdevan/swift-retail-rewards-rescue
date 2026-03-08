import XCTest

final class AppSmokeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testCoreNavigationSmokeFlow() {
        let emailField = app.textFields["login_email"]
        let passwordField = app.secureTextFields["login_password"]
        let submitButton = app.buttons["login_submit"]

        XCTAssertTrue(emailField.waitForExistence(timeout: 3))
        XCTAssertTrue(passwordField.exists)
        XCTAssertTrue(submitButton.exists)
        submitButton.tap()

        let offersTable = app.tables["offers_table"]
        XCTAssertTrue(offersTable.waitForExistence(timeout: 5))

        let firstOffer = offersTable.cells.element(boundBy: 0)
        if firstOffer.waitForExistence(timeout: 4) {
            firstOffer.tap()

            let saveButton = app.buttons["offer_detail_save_button"]
            if saveButton.waitForExistence(timeout: 2), saveButton.isEnabled {
                saveButton.tap()
            }

            app.navigationBars.buttons.element(boundBy: 0).tap()
        }

        app.tabBars.buttons["Saved"].tap()
        XCTAssertTrue(app.tables["saved_offers_table"].waitForExistence(timeout: 3))

        app.tabBars.buttons["Inbox"].tap()
        XCTAssertTrue(app.tables["inbox_table"].waitForExistence(timeout: 3))

        app.tabBars.buttons["Wallet"].tap()
        let walletLoaded = app.staticTexts["Reward Balance"].waitForExistence(timeout: 4)
            || app.staticTexts["Wallet refresh failed"].waitForExistence(timeout: 1)
            || app.staticTexts["No wallet items"].waitForExistence(timeout: 1)
        XCTAssertTrue(walletLoaded)
    }
}
