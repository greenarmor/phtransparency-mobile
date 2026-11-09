import XCTest

final class SmokeTests: XCTestCase {
    func shot(_ name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        a.name = name; a.lifetime = .keepAlways; add(a)
    }

    func testWalkthrough() {
        let app = XCUIApplication(); app.launch()
        app.buttons["See the budget"].tap()
        XCTAssertTrue(app.navigationBars["All Philippines"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.staticTexts["In the House bill only"].waitForExistence(timeout: 30))
        shot("1-national")

        app.staticTexts["In the House bill only"].tap()
        XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 30))
        shot("2-group-list")
        app.cells.element(boundBy: 1).tap()
        XCTAssertTrue(app.navigationBars["Project"].waitForExistence(timeout: 10))
        shot("3-project")

        app.tabBars.buttons["Regions"].tap()
        XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 30))
        shot("4-regions")
        app.cells.element(boundBy: 1).tap()
        XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 30))
        shot("5-region-projects")

        app.tabBars.buttons["Districts"].tap()
        XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 30))
        shot("6-districts")
        app.cells.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Representative"].waitForExistence(timeout: 30))
        shot("7-district")
        let office = app.cells.containing(NSPredicate(format: "label CONTAINS 'DEO'")).firstMatch
        XCTAssertTrue(office.waitForExistence(timeout: 10))
        office.tap()
        XCTAssertTrue(app.cells.element(boundBy: 1).waitForExistence(timeout: 30))
        shot("8-office-projects")

        app.tabBars.buttons["Enacted"].tap()
        XCTAssertTrue(app.staticTexts["Enacted budget, 2020–2026"].waitForExistence(timeout: 30))
        shot("9-enacted")
        app.tabBars.buttons["About"].tap()
        shot("10-about")
    }
}
