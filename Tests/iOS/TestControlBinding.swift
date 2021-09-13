//
//  TestControlBinding.swift
//  Test-iOS
//
//  Created by BB9z on 2020/4/11.
//  Copyright © 2020 RFUI. All rights reserved.
//

import XCTest

@objc class CustomControl: NSObject {
    @objc var enabled: Bool = true
}

private class TestControlBinding: XCTestCase {
    // No default base url
    lazy var api: TestAPI = {
        let api = TestAPI()
        let uc = URLSessionConfiguration.default
        uc.timeoutIntervalForRequest = 5
        api.sessionConfiguration = uc
        api.loadTestDefines()
        return api
    }()

    func testTimeout() {
        let completeExpectation = expectation(description: "")
        let button = UIButton()
        let barItem = UIBarButtonItem()
        let activityIndicator = UIActivityIndicatorView()
        let refreshControl = UIRefreshControl()
        let customControl = CustomControl()
        XCTAssertTrue(Thread.isMainThread)

        XCTAssertTrue(button.isEnabled)
        XCTAssertTrue(barItem.isEnabled)
        XCTAssertFalse(activityIndicator.isAnimating)
        XCTAssertFalse(refreshControl.isRefreshing)
        XCTAssertTrue(refreshControl.isEnabled)
        XCTAssertTrue(customControl.enabled)
        let _ = api.request(name: "Delay") { c in
            c.timeoutInterval = 1
            c.parameters = ["time": 10]
            c.bindControls = [button, barItem, activityIndicator, refreshControl, customControl]
            c.completion { _, _, _ in
                XCTAssertTrue(button.isEnabled)
                XCTAssertTrue(barItem.isEnabled)
                XCTAssertFalse(activityIndicator.isAnimating)
                XCTAssertFalse(refreshControl.isRefreshing)
                XCTAssertTrue(refreshControl.isEnabled)
                XCTAssertTrue(customControl.enabled)
                completeExpectation.fulfill()
            }
        }
        XCTAssertFalse(button.isEnabled)
        XCTAssertFalse(barItem.isEnabled)
        XCTAssertTrue(activityIndicator.isAnimating)
        XCTAssertTrue(refreshControl.isRefreshing)
        XCTAssertTrue(refreshControl.isEnabled)
        XCTAssertFalse(customControl.enabled)

        wait(for: [completeExpectation], timeout: 10)

        XCTAssertTrue(button.isEnabled)
        XCTAssertTrue(barItem.isEnabled)
        XCTAssertFalse(activityIndicator.isAnimating)
        XCTAssertFalse(refreshControl.isRefreshing)
        XCTAssertTrue(refreshControl.isEnabled)
        XCTAssertTrue(customControl.enabled)
    }
}
