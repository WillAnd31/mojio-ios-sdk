/******************************************************************************
 * Moj.io Inc. CONFIDENTIAL
 * 2017 Copyright Moj.io Inc.
 * All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains, the property of
 * Moj.io Inc. and its suppliers, if any.  The intellectual and technical
 * concepts contained herein are proprietary to Moj.io Inc. and its suppliers
 * and may be covered by Patents, pending patents, and are protected by trade
 * secret or copyright law.
 *
 * Dissemination of this information or reproduction of this material is strictly
 * forbidden unless prior written permission is obtained from Moj.io Inc.
 *******************************************************************************/

import Foundation
import ObjectMapper

public protocol BaseActivityLocation: Mappable {
    var Id: String? {get set}
    var ActivityType: String? {get set}
    var Href: String? {get set}
    var Name: String? {get set}
    var NameMap: Dictionary<String, String>? {get set}
}

extension BaseActivityLocation {

    public mutating func mapping(map: Map) {
        self.baseActivityLocationMapping(map: map)
    }
    
    public mutating func baseActivityLocationMapping(map: Map) {
        Id <- map["Id"]
        ActivityType <- map["Type"]
        Href <- map["Href"]
        Name <- map["Name"]
        NameMap <- map["NameMap"]
    }
}
