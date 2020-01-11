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
        let successExpectation = expectation(description: "Request Success")
        let complateExpectation = expectation(description: "Request Complate")
        let context = RFAPIRequestConext()
        context.groupIdentifier = "v1"
        api.request(withName: "Anything", parameters: ["path": "lookup"], controlInfo: context, success: { task, response in
            debugPrint(response)
            successExpectation.fulfill()
        }, failure: { task, error in
            assert(false, error.localizedDescription)
        }) { _ in
            complateExpectation.fulfill()
        }
        wait(for: [successExpectation, complateExpectation], timeout: 20, enforceOrder: true)
    }
}
