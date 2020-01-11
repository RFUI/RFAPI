//
//  TestDefineManager.swift
//  RFAPI
//
//  Created by BB9z on 29/03/2018.
//  Copyright © 2018 RFUI. All rights reserved.
//

import XCTest

@objc(TestRequestSerializer)
class TestRequestSerializer: AFHTTPRequestSerializer {}

@objc(TestResponseSerializer)
class TestResponseSerializer: AFHTTPResponseSerializer {}

class TestDefineManager: XCTestCase {

    lazy var manager = RFAPIDefineManager()
    lazy var rawConfig: [String: [String: Any]] = {
        let dataURL = Bundle(for: type(of: self)).url(forResource: "test_defines", withExtension: "plist")!
        return NSDictionary(contentsOf: dataURL) as! [String: [String: Any]]
    }()

    override func setUp() {
        super.setUp()
        manager.setDefinesWithRulesInfo(rawConfig)
    }

    func testDefinesSetter() {
        XCTAssert(manager.defines.count >= 2)
        manager.defines = []
        XCTAssert(manager.defines.count == 0)

        let define = RFAPIDefine()
        XCTAssertThrowsError(try RTHelper.catchException {
            manager.defines = [ define ]
        })
        XCTAssertEqual(manager.defines, [])
        define.name = RFAPIName(rawValue: "test")
        XCTAssertNoThrow(manager.defines = [ define ])
        XCTAssertEqual(manager.defines, [ define ])
    }

    func testSerializersGet() {
        XCTAssert(type(of: manager.defaultRequestSerializer) === AFJSONRequestSerializer.self)
        XCTAssert(type(of: manager.defaultResponseSerializer) === AFJSONResponseSerializer.self)

        let testSerializersDefine = manager.define(forName: RFAPIName(rawValue: "Serializers"))
        XCTAssertNotNil(testSerializersDefine)
        let testRequestS = manager.requestSerializer(for: testSerializersDefine)
        XCTAssert(type(of: testRequestS) === TestRequestSerializer.self)
        let testResponseS = manager.responseSerializer(for: testSerializersDefine)
        XCTAssert(type(of: testResponseS) === TestResponseSerializer.self)

        let noSerializersDefine = manager.define(forName: RFAPIName(rawValue: "NoSerializers"))
        let noRequestS = manager.requestSerializer(for: noSerializersDefine)
        XCTAssert(noRequestS === manager.defaultRequestSerializer)
        let noResponseS = manager.responseSerializer(for: noSerializersDefine)
        XCTAssert(noResponseS === manager.defaultResponseSerializer)
    }

    func testAllPropertiesLoad() {
        let define2 = manager.define(forName: RFAPIName(rawValue: "AllProperties"))!
        XCTAssertNotNil(define2)
        XCTAssertEqual("AllProperties", define2.name!.rawValue)
        XCTAssertEqual(URL(string: "http://example.com"), define2.baseURL)
        XCTAssertEqual("api/v2/", define2.pathPrefix)
        XCTAssertEqual("do", define2.path)
        XCTAssertEqual("PUT", define2.method)
        XCTAssertEqual(["xxx-foo": "bar"], define2.httpRequestHeaders as! [String: String])
        XCTAssertEqual(["query": "text"], define2.defaultParameters as! [String: String])
        XCTAssertEqual(true, define2.needsAuthorization)
        XCTAssertTrue(AFHTTPRequestSerializer.self === define2.requestSerializerClass)
        XCTAssertEqual(RFAPIDefineCachePolicy.cachePolicyExpire, define2.cachePolicy)
        XCTAssertEqual(300, define2.expire)
        XCTAssertEqual(RFAPIDefineOfflinePolicy.offlinePolicyLoadCache, define2.offlinePolicy)
        XCTAssertTrue(AFHTTPResponseSerializer.self === define2.responseSerializerClass)
        XCTAssertEqual(RFAPIDefineResponseExpectType.object, define2.responseExpectType)
        XCTAssertEqual("RFAPIDefine", define2.responseClass)
        XCTAssertEqual(true, define2.responseAcceptNull)
        XCTAssertEqual(["user": "info"], define2.userInfo as! [String: String])
        XCTAssertEqual("This is a test", define2.notes)
    }

    func testMakeURL() {
        let define = RFAPIDefine()
        define.path = "zz://?a=b"

        let p = [RFAPIRequestForceQuryStringParametersKey: ["a2": 123]] as NSMutableDictionary
        let url = try! manager.requestURL(for: define, parameters: p)
        XCTAssertEqual(url.absoluteString, "zz://?a=b&a2=123")
    }

    func testMakeURLParametersInPath() {
        let define = RFAPIDefine()
        define.path = "zz://example.com:{port}/{path}/{no-exsist}?{q1}=b"

        let p = ["port": 8080, "path": "hello-word", "q1": "key1", "key2": "c" ] as NSMutableDictionary
        let url = try! manager.requestURL(for: define, parameters: p)
        // No key2
        XCTAssertEqual(url.absoluteString, "zz://example.com:8080/hello-word/?key1=b")
    }

    func testMakeURLBaseAndPrefix() {
        let define = RFAPIDefine()
        define.baseURL = URL(string: "http://example.com/api/")
        define.pathPrefix = "/root/"
        define.path = "doit"

        var url = try! manager.requestURL(for: define, parameters: nil)
        XCTAssertEqual(url.absoluteString, "http://example.com/root/doit")

        define.pathPrefix = "relative/"
        url = try! manager.requestURL(for: define, parameters: nil)
        XCTAssertEqual(url.absoluteString, "http://example.com/api/relative/doit")

        define.path = "/doit/"
        url = try! manager.requestURL(for: define, parameters: nil)
        XCTAssertEqual(url.absoluteString, "http://example.com/api/relative//doit/")

        define.pathPrefix = "foo"
        define.path = "bar"
        url = try! manager.requestURL(for: define, parameters: nil)
        XCTAssertEqual(url.absoluteString, "http://example.com/api/foobar")
     }
}
