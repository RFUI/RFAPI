//
//  TestAPI.swift
//  Example-iOS
//
//  Created by BB9z on 2020/1/3.
//  Copyright © 2020 RFUI. All rights reserved.
//

class TestAPI: RFAPI {
    override init() {
        super.init()
        guard let configPath = Bundle.main.path(forResource: "TestAPIDefine", ofType: "plist"),
            let rules = NSDictionary(contentsOfFile: configPath) as? [String : [String : Any]] else {
            fatalError()
        }
        defineManager.setDefinesWithRulesInfo(rules)
        defineManager.defaultResponseSerializer = AFJSONResponseSerializer(readingOptions: .allowFragments)
        networkActivityIndicatorManager = RFSVProgressMessageManager()
        modelTransformer = RFAPIJSONModelTransformer()
    }

    override func preprocessingRequest(parametersRef: UnsafeMutablePointer<NSMutableDictionary?>, httpHeadersRef: UnsafeMutablePointer<NSMutableDictionary?>, parameters: [AnyHashable : Any]?, define: RFAPIDefine, context: RFAPIRequestConext) {
        super.preprocessingRequest(parametersRef: parametersRef, httpHeadersRef: httpHeadersRef, parameters: parameters, define: define, context: context)
    }

    override func finalizeSerializedRequest(_ request: NSMutableURLRequest, define: RFAPIDefine, context: RFAPIRequestConext) -> NSMutableURLRequest {
        return request
    }

    override func generalHandlerForError(_ error: Error, define: RFAPIDefine, task: RFAPITask, failure: RFAPIRequestFailureCallback? = nil) -> Bool {
        return true
    }

    override func isSuccessResponse(_ responseObjectRef: UnsafeMutablePointer<AnyObject?>, error: NSErrorPointer) -> Bool {
        return super.isSuccessResponse(responseObjectRef, error: error)
    }
}
