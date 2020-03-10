//
//  DefineLoad.swift
//  RFAPI
//
//  Created by BB9z on 2020/3/10.
//  Copyright © 2020 RFUI. All rights reserved.
//

extension RFAPI {
    /// Load api defines in test_defines.plist
    func loadTestDefines() {
        let defineConfigURL = Bundle(for: type(of: self)).url(forResource: "test_defines", withExtension: "plist")!
        let defineConfig = NSDictionary(contentsOf: defineConfigURL) as! [String: [String: Any]]
        defineManager.setDefinesWithRulesInfo(defineConfig)
    }
}
