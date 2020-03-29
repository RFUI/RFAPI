//
//  TestEntity.swift
//  Example-iOS
//
//  Created by BB9z on 2020/3/29.
//  Copyright © 2020 RFUI. All rights reserved.
//

import Foundation

@objc(RFDTestEntity)
class RFDTestEntity : JSONModel {
    @objc var uid: Int64 = -1
    @objc var name: String?

    override class func keyMapper() -> JSONKeyMapper! {
        return JSONKeyMapper(modelToJSONDictionary: [#keyPath(RFDTestEntity.uid) : "id"])
    }

    override class func propertyIsOptional(_ propertyName: String!) -> Bool {
        // All property is optional.
        return true
    }
}
