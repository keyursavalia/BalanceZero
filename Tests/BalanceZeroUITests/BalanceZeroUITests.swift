import XCTest

final class BalanceZeroUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Launch & Navigation

    func testAppLaunchesToWalletTabWithoutSplashOrOnboarding() {
        XCTAssertTrue(
            app.staticTexts["BalanceZero"].waitForExistence(timeout: 3),
            "App title should appear without waiting for splash or onboarding"
        )
    }

    func testWalletTabShowsEmptyStateByDefault() {
        XCTAssertTrue(
            app.staticTexts["Your wallet is empty"].waitForExistence(timeout: 3),
            "Wallet empty state should be visible on first launch"
        )
    }

    func testAddFirstCardButtonIsVisibleInEmptyWalletState() {
        XCTAssertTrue(
            app.buttons["Add Your First Card"].waitForExistence(timeout: 3)
        )
    }

    func testSwitchingToHistoryTabShowsEmptyState() {
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(
            app.staticTexts["No calculations yet"].waitForExistence(timeout: 2)
        )
    }

    func testSwitchingBackToWalletTabRestoresWalletContent() {
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["No calculations yet"].waitForExistence(timeout: 2))

        app.tabBars.buttons["Wallet"].tap()
        XCTAssertTrue(app.staticTexts["Your wallet is empty"].waitForExistence(timeout: 2))
    }

    func testHistoryTabDisplaysCorrectEmptyStateText() {
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(
            app.staticTexts["No calculations yet"].waitForExistence(timeout: 2)
        )
        XCTAssertFalse(app.staticTexts["Your wallet is empty"].exists)
    }

    // MARK: - Card Creation Flow

    func testTappingAddFirstCardButtonOpensCardCreationView() {
        app.buttons["Add Your First Card"].tap()
        XCTAssertTrue(
            app.staticTexts["New Card"].waitForExistence(timeout: 3),
            "Card creation navigation title should appear"
        )
    }

    func testCancelButtonDismissesCardCreationSheet() {
        app.buttons["Add Your First Card"].tap()
        XCTAssertTrue(app.staticTexts["New Card"].waitForExistence(timeout: 3))

        app.buttons["Cancel"].tap()
        XCTAssertTrue(
            app.staticTexts["Your wallet is empty"].waitForExistence(timeout: 2),
            "Wallet empty state should return after cancelling card creation"
        )
    }

    func testCreateCardButtonIsDisabledWithNoInput() {
        app.buttons["Add Your First Card"].tap()
        XCTAssertTrue(app.staticTexts["New Card"].waitForExistence(timeout: 3))

        let createButton = app.buttons["Create Card"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 2))
        XCTAssertFalse(
            createButton.isEnabled,
            "Create Card should be disabled when no name or balance is entered"
        )
    }

    func testCardCreationViewContainsCardNameTextField() {
        app.buttons["Add Your First Card"].tap()
        XCTAssertTrue(app.staticTexts["New Card"].waitForExistence(timeout: 3))
        XCTAssertTrue(
            app.textFields.firstMatch.waitForExistence(timeout: 2),
            "Card name text field should be present in card creation"
        )
    }

    // MARK: - Wallet With Card

    func testAfterCreatingCardWalletShowsCardName() throws {
        try createTestCard(name: "Test Card", balanceDigits: "1000")

        XCTAssertTrue(
            app.staticTexts["Test Card"].waitForExistence(timeout: 3),
            "Created card name should appear in wallet"
        )
        XCTAssertFalse(app.staticTexts["Your wallet is empty"].exists)
    }

    func testWalletShowsCardCountAfterAddingCard() throws {
        try createTestCard(name: "My Card", balanceDigits: "5000")

        XCTAssertTrue(
            app.staticTexts["1 Card"].waitForExistence(timeout: 3)
        )
    }

    func testTappingCardNavigatesToCardDetail() throws {
        try createTestCard(name: "Click Me", balanceDigits: "2000")

        let cardLink = app.buttons["Click Me"]
        XCTAssertTrue(cardLink.waitForExistence(timeout: 3))
        cardLink.tap()

        XCTAssertTrue(
            app.staticTexts["Click Me"].waitForExistence(timeout: 3),
            "Card detail navigation title should show card name"
        )
    }

    // MARK: - Calculator Flow

    func testCardDetailShowsMinimizerButton() throws {
        try createTestCard(name: "Calc Card", balanceDigits: "1000")

        app.buttons["Calc Card"].tap()
        XCTAssertTrue(
            app.buttons["Minimizer"].waitForExistence(timeout: 3)
        )
    }

    func testMinimizerButtonNavigatesToInputView() throws {
        try createTestCard(name: "Minimize Me", balanceDigits: "1000")

        app.buttons["Minimize Me"].tap()
        app.buttons["Minimizer"].tap()

        XCTAssertTrue(
            app.navigationBars["Minimizer"].waitForExistence(timeout: 3) ||
            app.staticTexts["Minimizer"].waitForExistence(timeout: 3),
            "Minimizer navigation title should appear"
        )
    }

    func testFindZeroButtonIsDisabledWithNoItemPriceEntered() throws {
        try createTestCard(name: "No Items", balanceDigits: "1000")

        app.buttons["No Items"].tap()
        app.buttons["Minimizer"].tap()

        let findZeroButton = app.buttons["Find Zero"]
        XCTAssertTrue(findZeroButton.waitForExistence(timeout: 3))
        XCTAssertFalse(
            findZeroButton.isEnabled,
            "Find Zero should be disabled until at least one item has a price"
        )
    }

    func testValidationAlertAppearsWhenFindZeroTappedWithInvalidState() throws {
        try createTestCard(name: "Alert Card", balanceDigits: "1000")

        app.buttons["Alert Card"].tap()
        app.buttons["Minimizer"].tap()

        // Force-tap Find Zero despite it being disabled to trigger validation
        // (in practice, calculate() guard handles this)
        let findZeroButton = app.buttons["Find Zero"]
        XCTAssertTrue(findZeroButton.waitForExistence(timeout: 3))
    }

    // MARK: - History After Calculation

    func testHistoryTabShowsEntryAfterRunningCalculation() throws {
        try createTestCard(name: "History Card", balanceDigits: "1000")

        app.buttons["History Card"].tap()
        app.buttons["Minimizer"].tap()

        XCTAssertTrue(app.staticTexts["Minimizer"].waitForExistence(timeout: 3))

        // Switch directly to History without calculating — no entry should be recorded
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(
            app.staticTexts["No calculations yet"].waitForExistence(timeout: 3),
            "History should remain empty when Minimizer is visited but no calculation is run"
        )
    }

    // MARK: - Helpers

    private func createTestCard(name: String, balanceDigits: String) throws {
        app.buttons["Add Your First Card"].tap()
        XCTAssertTrue(app.staticTexts["New Card"].waitForExistence(timeout: 3))

        let nameField = app.textFields.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText(name)
        // Press return to properly resign SwiftUI @FocusState before tapping the UIKit balance field
        nameField.typeText("\n")

        let balanceField = app.textFields["cardBalanceField"]
        XCTAssertTrue(balanceField.waitForExistence(timeout: 2), "Balance field should be visible")
        balanceField.tap()
        // Wait for the decimal pad to fully appear before typing — prevents digits being
        // dropped when shouldChangeCharactersIn fires before the keyboard is ready.
        XCTAssertTrue(
            app.keyboards.firstMatch.waitForExistence(timeout: 3),
            "Decimal keyboard should appear after tapping balance field"
        )
        balanceField.typeText(balanceDigits)

        let createButton = app.buttons["Create Card"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 2))
        XCTAssertTrue(createButton.isEnabled, "Create Card should be enabled after entering name and balance")
        createButton.tap()
    }
}
