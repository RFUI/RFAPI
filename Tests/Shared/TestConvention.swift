//
//  TestConvention.swift
//  RFAPI
//
//  Created by BB9z on 2020/1/17.
//  Copyright © 2020 RFUI. All rights reserved.
//

import XCTest

class TestConvention: XCTestCase {

    // Has default base url
    lazy var api: TestAPI = {
        let api = TestAPI()
        api.baseURL = URL(string: "https://httpbin.org")
        let defineConfigURL = Bundle(for: type(of: self)).url(forResource: "test_defines", withExtension: "plist")!
        let defineConfig = NSDictionary(contentsOf: defineConfigURL) as! [String: [String: Any]]
        api.defineManager.setDefinesWithRulesInfo(defineConfig)
        return api
    }()

    func testCallbacksOrder() {
        let expSuccess1 = expectation(description: "success")
        let expFinsh1 = expectation(description: "finish")
        let expComplete1 = expectation(description: "complate")
        api.request(name: "Status") { c in
            c.parameters = ["code": 200]
            c.success { _, _ in
                expSuccess1.fulfill()
            }
            c.failure { _, _ in
                fatalError("This request should success.")
            }
            c.finished { _, _ in
                expFinsh1.fulfill()
            }
            c.complation { _, _, _ in
                expComplete1.fulfill()
            }
        }
        wait(for: [expSuccess1, expFinsh1, expComplete1], timeout: 10, enforceOrder: true)

        let expFail2 = expectation(description: "fail")
        let expFinsh2 = expectation(description: "finish")
        let expComplete2 = expectation(description: "complate")
        api.request(name: "Status") { c in
            c.parameters = ["code": 500]
            c.success { _, _ in
                fatalError("This request should fail.")
            }
            c.failure { _, _ in
                expFail2.fulfill()
            }
            c.finished { _, _ in
                expFinsh2.fulfill()
            }
            c.complation { _, _, _ in
                expComplete2.fulfill()
            }
        }
        wait(for: [expFail2, expFinsh2, expComplete2], timeout: 10, enforceOrder: true)
    }

    func testTaskObjectReturnsWhenSessionTaskMake() {
        let cannotMakeDefine = RFAPIDefine()
        cannotMakeDefine.name = RFAPIName(rawValue: "")
        var request = api.request(define: cannotMakeDefine) { c in
            c.complation { task, _, _ in
                XCTAssertNil(task)
            }
        }
        XCTAssertNil(request)

        request = api.request(name: "Anything"){ c in
            c.complation { task, _, _ in
                XCTAssertNotNil(task)
            }
        }
        XCTAssertNotNil(request)
        request?.cancel()
    }

    func testCallbacksAlwaysCalledAfterFunctionReturns() {
        let cannotMakeDefine = RFAPIDefine()
        let cannotMakeCallbackExpectation = expectation(description: "callback")
        let cannotMakeEndExpectation = expectation(description: "request called")
        let request = api.request(define: cannotMakeDefine) { c in
            c.identifier = ""
            c.failure { task, error in
                cannotMakeCallbackExpectation.fulfill()
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNil(task)
                XCTAssertNotNil(error)
            }
        }
        XCTAssertNil(request)
        cannotMakeEndExpectation.fulfill()
        // Callbacks should always have a delay.
        wait(for: [cannotMakeEndExpectation, cannotMakeCallbackExpectation], timeout: 0.1, enforceOrder: true)
    }
}
