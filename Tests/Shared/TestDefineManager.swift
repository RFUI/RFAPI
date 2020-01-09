//
//  TestDefineManager.swift
//  RFAPI
//
//  Created by BB9z on 29/03/2018.
//  Copyright © 2018 RFUI. All rights reserved.
//

import XCTest

class TestDefineManager: XCTestCase {

    lazy var manager = RFAPIDefineManager()

    func testURLBuild() {
        let define = RFAPIDefine()
        define.path = "zz://?a=b"

        let p = [RFAPIRequestForceQuryStringParametersKey: ["a2": 123]] as NSMutableDictionary
        let url = try! manager.requestURL(for: define, parameters: p)
        debugPrint(url)
    }
}
