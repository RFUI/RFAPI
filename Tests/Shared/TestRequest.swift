//
//  TestRequest.swift
//  RFAPI
//
//  Created by BB9z on 2020/1/10.
//  Copyright © 2020 RFUI. All rights reserved.
//

import XCTest

class TestAPI: RFAPI {
    var deallocExpectation: XCTestExpectation?

    deinit {
        deallocExpectation?.fulfill()
    }
}

class TestRequest: XCTestCase {

    // No default base url
    lazy var api: TestAPI = {
        let api = TestAPI()
        let uc = URLSessionConfiguration.default
        uc.timeoutIntervalForRequest = 5
        api.sessionConfiguration = uc
        api.loadTestDefines()
        return api
    }()

    func testV1Interface() {
        let successExpectation = expectation(description: "Request Succeed")
        let completeExpectation = expectation(description: "Request Completed")
        let context = RFAPIRequestConext()
        context.groupIdentifier = "v1"
        api.request(withName: "Anything", parameters: ["path": "lookup"], controlInfo: context, success: { task, response in
            guard let rsp = response as? [String: Any] else {
                XCTAssert(false, "Response invalid.")
                return
            }
            XCTAssertEqual(rsp["url"] as! String?, "https://httpbin.org/anything/lookup")
            successExpectation.fulfill()
        }, failure: { task, error in
            XCTAssert(false, error.localizedDescription)
        }) { _ in
            completeExpectation.fulfill()
        }
        wait(for: [successExpectation, completeExpectation], timeout: 10, enforceOrder: true)
    }

    func testIdentifierControl() {
        
    }

    func testFormUpload() {

    }

    func testTaskCancelImmediately() {
        let completeExpectation = expectation(description: "")
        let request = api.request(name: "Delay") { c in
            c.success { _, _ in
                XCTAssert(false, "This request should fail.")
            }
            c.failure { _, _ in
                XCTAssert(false, "Do not call the failure callback when canceling.")
            }
            c.finished { task, success in
                XCTAssertFalse(success)
                guard let task = task else {
                    XCTAssert(false, "Task should have")
                    return
                }
                XCTAssertNil(task.response)
                XCTAssertNil(task.responseObject)
            }
            c.complation { task, rsp, error in
                XCTAssertNotNil(task)
                XCTAssertNil(rsp)
                XCTAssertNil(error)
                XCTAssertNotNil(task?.error)
                completeExpectation.fulfill()
            }
        }
        request?.cancel()
        XCTAssertNotNil(request)
        wait(for: [completeExpectation], timeout: 1)
    }

    func testTaskCancelAfterAWhile() {
        let completeExpectation = expectation(description: "")
        let request = api.request(name: "Delay") { c in
            c.success { _, _ in
                XCTAssert(false, "This request should fail.")
            }
            c.failure { _, _ in
                XCTAssert(false, "Do not call the failure callback when canceling.")
            }
            c.finished { task, success in
                XCTAssertFalse(success)
                guard let task = task else {
                    XCTAssert(false, "Task should have")
                    return
                }
                XCTAssertNil(task.response)
                XCTAssertNil(task.responseObject)
            }
            c.complation { task, rsp, error in
                XCTAssertNotNil(task)
                XCTAssertNil(rsp)
                XCTAssertNil(error)
                XCTAssertNotNil(task?.error)
                completeExpectation.fulfill()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            request?.cancel()
        }
        XCTAssertNotNil(request)
        wait(for: [completeExpectation], timeout: 2)
    }

    func testTimeout() {
        let completeExpectation = expectation(description: "")
        let request = api.request(name: "Delay") { c in
            c.timeoutInterval = 1
            c.parameters = ["time": 10]
            c.success { _, _ in
                XCTAssert(false, "This request should fail.")
            }
            c.failure { task, error in
                XCTAssertNotNil(task)
                XCTAssertNotNil(error)
                let e = error as NSError
                XCTAssertEqual(e.code, NSURLErrorTimedOut)
                XCTAssertEqual(e.domain, NSURLErrorDomain)
            }
            c.finished { task, s in
                XCTAssertNotNil(task)
                XCTAssertFalse(s)
            }
            c.complation { task, rsp, error in
                XCTAssertNotNil(task)
                XCTAssertNil(rsp)
                XCTAssertNotNil(error)
                debugPrint(error!)
                completeExpectation.fulfill()
            }
        }
        XCTAssertEqual(request?.originalRequest?.timeoutInterval, 1)
        wait(for: [completeExpectation], timeout: 10)
        XCTAssertNotNil(request?.error)
    }

    func testHTTPStatusError() {
        let completeExpectation = expectation(description: "")
        let request = api.request(name: "404") { c in
            c.success { _, _ in
                XCTAssert(false, "This request should fail.")
            }
            c.failure { task, error in
                XCTAssertNotNil(task)
                XCTAssertNotNil(error)
            }
            c.finished { task, s in
                XCTAssertNotNil(task)
                XCTAssertFalse(s)
            }
            c.complation { task, rsp, error in
                debugPrint(error!)
                XCTAssertNotNil(task)
                XCTAssertNil(rsp)
                XCTAssertNotNil(error)
                completeExpectation.fulfill()
            }
        }
        wait(for: [completeExpectation], timeout: 10)
        XCTAssertNotNil(request?.error)
        guard let httpResponse = request?.response as? HTTPURLResponse else {
            XCTAssert(false, "Response should be HTTPURLResponse")
            return
        }
        XCTAssertEqual(httpResponse.statusCode, 404)
    }

    func testRedirects() {
        let successExpectation = expectation(description: "Request Succeed")

        let redirectTimesDefine = RFAPIDefine()
        redirectTimesDefine.path = "https://httpbin.org/redirect/3"
        let request = api.request(define: redirectTimesDefine) { c in
            c.identifier = ""
            c.success { task, response in
                guard let rsp = response as? [String: Any] else {
                    XCTAssert(false, "Response invalid.")
                    return
                }
                print(rsp)
                XCTAssertEqual(task.originalRequest?.url?.absoluteURL.absoluteString, "https://httpbin.org/redirect/3")
                XCTAssertEqual(task.currentRequest?.url?.absoluteURL.absoluteString, "https://httpbin.org/get")
                successExpectation.fulfill()
            }
        }
        wait(for: [successExpectation], timeout: 15, enforceOrder: true)
        XCTAssertNil(request?.error)
    }
}
