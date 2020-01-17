//
//  TestRequest.swift
//  RFAPI
//
//  Created by BB9z on 2020/1/10.
//  Copyright © 2020 RFUI. All rights reserved.
//

import XCTest

class TestAPI: RFAPI {

}

class TestRequest: XCTestCase {
    lazy var api: TestAPI = {
        let api = TestAPI()
        let defineConfigURL = Bundle(for: type(of: self)).url(forResource: "test_defines", withExtension: "plist")!
        let defineConfig = NSDictionary(contentsOf: defineConfigURL) as! [String: [String: Any]]
        api.defineManager.setDefinesWithRulesInfo(defineConfig)
        return api
    }()

    func testV1Interface() {
        let successExpectation = expectation(description: "Request Succeed")
        let completeExpectation = expectation(description: "Request Completed")
        let context = RFAPIRequestConext()
        context.groupIdentifier = "v1"
        api.request(withName: "Anything", parameters: ["path": "lookup"], controlInfo: context, success: { task, response in
            guard let rsp = response as? [String: Any] else {
                fatalError("Response invalid")
            }
            XCTAssertEqual(rsp["url"] as! String?, "https://httpbin.org/anything/lookup")
            successExpectation.fulfill()
        }, failure: { task, error in
            assert(false, error.localizedDescription)
        }) { _ in
            completeExpectation.fulfill()
        }
        wait(for: [successExpectation, completeExpectation], timeout: 10, enforceOrder: true)
    }

    func testHTTPStatusError() {
        let failureExpectation = expectation(description: "Request Fails")
        let finishedExpectation = expectation(description: "Request Finished")
        let completeExpectation = expectation(description: "Request Completed")
        api.request(name: "404") { c in
            c.success { _, _ in
                fatalError("This request should fail.")
            }
            c.failure { task, error in
                XCTAssertNotNil(task)
                debugPrint(error)
                failureExpectation.fulfill()
            }
            c.finished { task, s in
                XCTAssertNotNil(task)
                XCTAssertFalse(s)
                finishedExpectation.fulfill()
            }
            c.complation { task, rsp, error in
                debugPrint(error!)
                XCTAssertNotNil(task)
                XCTAssertNil(rsp)
                XCTAssertNotNil(error)
                completeExpectation.fulfill()
            }
        }
        wait(for: [failureExpectation, finishedExpectation, completeExpectation], timeout: 10, enforceOrder: true)
    }
}
