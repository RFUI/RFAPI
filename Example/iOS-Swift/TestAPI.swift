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
}
