import XCTest

final class SelectionSyncTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        // Wait for the window to appear
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 10), "App window should appear")
        // Give extra time for content to render and data to load
        sleep(5)
    }

    /// Helper: find the "N selected" element (an .other element with label containing "selected")
    private func findSelectedElement() -> XCUIElement {
        let pred = NSPredicate(format: "label CONTAINS 'selected'")
        return app.descendants(matching: .other).matching(pred).firstMatch
    }

    /// Test: clicking a photo in the sidebar selects it
    func testSidebarClickSelectsPhoto() throws {
        let selectedEl = findSelectedElement()
        XCTAssertTrue(selectedEl.waitForExistence(timeout: 15),
            "App should show a 'selected' element")
        XCTAssertTrue(selectedEl.label.contains("0 selected"),
            "Initially 0 selected, got: \(selectedEl.label)")

        // Find a photo row by accessibility identifier pattern
        let photoRowPredicate = NSPredicate(format: "identifier BEGINSWITH 'photoRow_'")
        let photoRows = app.staticTexts.matching(photoRowPredicate)
        guard photoRows.count > 0 else {
            // No photos loaded - skip
            return
        }

        let firstRow = photoRows.element(boundBy: 0)
        XCTAssertTrue(firstRow.exists, "First photo row should exist")
        firstRow.click()
        sleep(2)

        // Re-find the element to get updated label
        let updatedEl = findSelectedElement()
        XCTAssertTrue(updatedEl.exists, "Selected element should still exist")
        XCTAssertTrue(updatedEl.label.contains("1 selected"),
            "After clicking a photo, should have 1 selected, got: \(updatedEl.label)")
    }

    /// Test: rectangle-select on the map updates the sidebar selection count
    func testRectangleSelectionUpdatesSidebar() throws {
        let selectedEl = findSelectedElement()
        XCTAssertTrue(selectedEl.waitForExistence(timeout: 15),
            "App should show a 'selected' element")
        XCTAssertTrue(selectedEl.label.contains("0 selected"),
            "Initially 0 selected, got: \(selectedEl.label)")

        // Click the Interpolate button first to get pins on the map
        let interpolateButton = app.buttons["Interpolate"]
        if interpolateButton.exists && interpolateButton.isEnabled {
            interpolateButton.click()
            sleep(3)
        }

        // Drag on the right portion of the window (where the map is)
        // The sidebar is on the left ~25%, the map is on the right ~75%
        let window = app.windows.firstMatch
        let startPoint = window.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.15))
        let endPoint = window.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.9))
        startPoint.press(forDuration: 0.1, thenDragTo: endPoint)

        // Wait for selection to propagate
        sleep(2)

        // Re-find the element to get updated label
        let updatedEl = findSelectedElement()
        XCTAssertTrue(updatedEl.exists, "Selected element should still exist")
        XCTAssertFalse(updatedEl.label.contains("0 selected"),
            "After rectangle selection, should have >0 selected, got: \(updatedEl.label)")
    }
}
