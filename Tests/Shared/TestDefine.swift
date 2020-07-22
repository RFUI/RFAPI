//
//  TestDefine.swift
//  RFAPI
//
//  Created by BB9z on 2020/1/7.
//  Copyright © 2020 RFUI. All rights reserved.
//

import XCTest

private class TestDefine: XCTestCase {

    func testMerge() {
        let r1 = RFAPIDefine()
        r1.name = RFAPIName(rawValue: "R1")
        r1.path = "111"
        r1.method = "m1"

        let r2 = RFAPIDefine()
        r2.name = RFAPIName(rawValue: "R2")
        r2.path = "222"
        r2.cachePolicy = .cachePolicyNoCache

        let r3 = r1.newDefineMergedDefault(r2)
        XCTAssertEqual(r3.name, r1.name)
        XCTAssertEqual(r3.path, r1.path)
        XCTAssertEqual(r3.method, r1.method)
        XCTAssertEqual(r3.cachePolicy, r2.cachePolicy)
        XCTAssertNotEqual(r3.cachePolicy, r1.cachePolicy)
    }

    func testCopy() {
        let r1 = RFAPIDefine()
        r1.path = "111"
        r1.cachePolicy = .cachePolicyAlways

        let r2 = r1.copy() as! RFAPIDefine
        XCTAssertFalse(r1.path! as NSString !== r2.path! as NSString)
        XCTAssertEqual(r1.path, r2.path)
        r2.path = "222"
        XCTAssertNotEqual(r1.path, r2.path)

        XCTAssertEqual(r1.cachePolicy, r2.cachePolicy)
        r2.cachePolicy = .cachePolicyExpire
        XCTAssertNotEqual(r1.cachePolicy, r2.cachePolicy)
    }

    func testCoding() {
        // Test load v1 data
        let dataURL = Bundle(for: type(of: self)).url(forResource: "archived_define_v1", withExtension: "plist")!
        let data = try! Data(contentsOf: dataURL)
        let defineV1: RFAPIDefine = try! NSKeyedUnarchiver.unarchivedObject(ofClass: RFAPIDefine.self, from: data)!
        XCTAssertNotNil(defineV1)
        debugPrint(defineV1)

        // This define has same properties with the v1 one, except pathPrefix.
        let define = RFAPIDefine()
        define.name = RFAPIName(rawValue: "ArchiveTest")
        define.baseURL = URL(string: "http://example.com")
        define.pathPrefix = "api/v2/"
        define.path = "do"
        define.method = "PUT"
        define.httpRequestHeaders = ["xxx-foo": "bar"]
        define.defaultParameters = ["query": "text"]
        define.needsAuthorization = true
        define.requestSerializerClass = AFHTTPRequestSerializer.self
        define.cachePolicy = .cachePolicyExpire
        define.expire = 300
        define.offlinePolicy = .offlinePolicyLoadCache
        define.responseSerializerClass = AFHTTPResponseSerializer.self
        define.responseExpectType = .object
        define.responseClass = "RFAPIDefine"
        define.responseAcceptNull = true
        define.userInfo = ["user": "info"]
        define.notes = "This is a test"

        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(NSUUID().uuidString)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
        let dataV2 = try! NSKeyedArchiver.archivedData(withRootObject: define, requiringSecureCoding: true)
        XCTAssert(dataV2.count > 100)
        try! dataV2.write(to: fileURL, options: [])
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        let defineV2: RFAPIDefine = try! NSKeyedUnarchiver.unarchivedObject(ofClass: RFAPIDefine.self, from: dataV2)!
        XCTAssertNotNil(defineV2)
        XCTAssertEqual(defineV1.name, defineV2.name)
        XCTAssertEqual(defineV1.baseURL, defineV2.baseURL)
        XCTAssertNotEqual(defineV1.pathPrefix, defineV2.pathPrefix)
        XCTAssertEqual(defineV1.path, defineV2.path)
        XCTAssertEqual(defineV1.method, defineV2.method)
        XCTAssertEqual(defineV1.httpRequestHeaders as! [String: String], defineV2.httpRequestHeaders as! [String: String])
        XCTAssertEqual(defineV1.defaultParameters as! [String: String], defineV2.defaultParameters as! [String: String])
        XCTAssertEqual(defineV1.needsAuthorization, defineV2.needsAuthorization)
        XCTAssertTrue(defineV1.requestSerializerClass === defineV2.requestSerializerClass)
        XCTAssertEqual(defineV1.cachePolicy, defineV2.cachePolicy)
        XCTAssertEqual(defineV1.expire, defineV2.expire)
        XCTAssertEqual(defineV1.offlinePolicy, defineV2.offlinePolicy)
        XCTAssertTrue(defineV1.responseSerializerClass === defineV2.responseSerializerClass)
        XCTAssertEqual(defineV1.responseExpectType, defineV2.responseExpectType)
        XCTAssertEqual(defineV1.responseClass, defineV2.responseClass)
        XCTAssertEqual(defineV1.responseExpectType, defineV2.responseExpectType)
        XCTAssertEqual(defineV1.responseAcceptNull, defineV2.responseAcceptNull)
        XCTAssertEqual(defineV1.userInfo as! [String: String], defineV2.userInfo as! [String: String])
        XCTAssertEqual(defineV1.notes, defineV2.notes)
    }
}
