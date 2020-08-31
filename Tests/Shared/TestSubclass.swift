//
//  TestSubclass.swift
//  RFAPI
//
//  Created by BB9z on 2020/3/10.
//  Copyright © 2020 RFUI. All rights reserved.
//

import XCTest

extension DispatchQueue {
    class var currentQueueLabel: String? {
        let name = __dispatch_queue_get_label(nil)
        let label = String(cString: name, encoding: .utf8)
        return label ?? OperationQueue.current?.underlyingQueue?.label ?? Thread.current.name
    }
}

fileprivate class Sub1API: RFAPI {

    override func preprocessingRequest(parametersRef: UnsafeMutablePointer<NSMutableDictionary?>, httpHeadersRef: UnsafeMutablePointer<NSMutableDictionary?>, parameters: [AnyHashable : Any]?, define: RFAPIDefine, context: RFAPIRequestConext) {
        if let queueName = context.userInfo?["QueueName"] as? String {
            XCTAssertEqual(DispatchQueue.currentQueueLabel, queueName)
        }
        super.preprocessingRequest(parametersRef: parametersRef, httpHeadersRef: httpHeadersRef, parameters: parameters, define: define, context: context)
    }

    override func finalizeSerializedRequest(_ request: NSMutableURLRequest, define: RFAPIDefine, context: RFAPIRequestConext) -> NSMutableURLRequest {
        if let queueName = context.userInfo?["QueueName"] as? String {
            XCTAssertEqual(DispatchQueue.currentQueueLabel, queueName)
        }
        return super.finalizeSerializedRequest(request, define: define, context: context)
    }

    override func generalHandlerForError(_ error: Error, define: RFAPIDefine, task: RFAPITask, failure: RFAPIRequestFailureCallback? = nil) -> Bool {
        XCTAssertEqual(DispatchQueue.currentQueueLabel, completionQueue.label)
        return super.generalHandlerForError(error, define: define, task: task, failure: failure)
    }

    override func isSuccessResponse(_ responseObjectRef: UnsafeMutablePointer<AnyObject?>, error: NSErrorPointer) -> Bool {
        XCTAssertEqual(DispatchQueue.currentQueueLabel, processingQueue.label)
        return super.isSuccessResponse(responseObjectRef, error: error)
    }

    var errorHandlerCalledCount = 0
}

private class TestSubclass: XCTestCase {
    func testFunctionThread() {
        let api = Sub1API()
        api.loadTestDefines()

        let sendQueue = DispatchQueue(label: "SendQueue")

        let completeExpectation = expectation(description: "Success Completed")
        let completeExpectation2 = expectation(description: "Fail Completed")
        sendQueue.async {
            api.request(name: "IsSuccess") { c in
                c.userInfo = ["QueueName": sendQueue.label]
                c.complation { _, _, _ in
                    completeExpectation.fulfill()
                }
            }
            api.request(name: "404") { c in
                c.userInfo = ["QueueName": sendQueue.label]
                c.complation { _, _, _ in
                    completeExpectation2.fulfill()
                }
            }
        }
        wait(for: [completeExpectation, completeExpectation2], timeout: 10, enforceOrder: false)
    }

    func testSuccessRequestShouldNotCallGeneralErrorHandler() {
        let api = Sub1API()
        api.loadTestDefines()
        let finishExpectation = expectation(description: "Request finished")
        api.request(name: "IsSuccess") { c in
            c.finished { _, _ in
                finishExpectation.fulfill()
            }
        }
        wait(for: [finishExpectation], timeout: 5)
        XCTAssert(api.errorHandlerCalledCount == 0)
    }

    func testCanceledRequestShouldNotCallGeneralErrorHandler() {
        let api = Sub1API()
        api.loadTestDefines()
        let finishExpectation = expectation(description: "Request finished")
        let task = api.request(name: "IsSuccess") { c in
            c.finished { _, _ in
                finishExpectation.fulfill()
            }
        }
        task?.cancel()
        wait(for: [finishExpectation], timeout: 5)
        XCTAssert(api.errorHandlerCalledCount == 0)
    }

    func testFailureRequestMustCallGeneralErrorHandler() {
        let api = Sub1API()
        api.loadTestDefines()
        let finishExpectation = expectation(description: "Request finished")
        api.request(name: "IsFailure") { c in
            c.finished { _, _ in
                finishExpectation.fulfill()
            }
        }
        wait(for: [finishExpectation], timeout: 5)
        XCTAssert(api.errorHandlerCalledCount == 1)
    }
}
