//
//  GiskardUITests.swift
//  GiskardUITests
//
//  Created by Timothy Powell on 7/15/25.
//

import XCTest

final class GiskardUITests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testEditorSmokeWorkflow_NoErrors() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--giskard-ui-automation")
        app.launch()

        let statusLabel = app.staticTexts["automationStatusText"]
        XCTAssertTrue(statusLabel.waitForExistence(timeout: 120), "Automation status was never shown.")
        XCTAssertTrue(
            statusLabel.label.hasPrefix("AUTOMATION_SUCCESS"),
            "Smoke scenario failed: \(statusLabel.label)"
        )

        let renderDiagnosticsLabel = app.staticTexts["renderDiagnosticsText"]
        XCTAssertTrue(
            renderDiagnosticsLabel.waitForExistence(timeout: 30),
            "Render diagnostics were never shown."
        )

        let renderExpectation = expectation(
            for: NSPredicate(
                format: "label CONTAINS '2D=1' AND label CONTAINS '3D=1' AND label CONTAINS 'camera=yes' AND label CONTAINS 'issues=0'"
            ),
            evaluatedWith: renderDiagnosticsLabel
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [renderExpectation], timeout: 30),
            .completed,
            "Render diagnostics did not confirm the expected preview frame: \(renderDiagnosticsLabel.label)"
        )

        app.terminate()
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
