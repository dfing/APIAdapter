//
//  RequestDataCache.swift
//  orange
//
//  Created by kayla.wen on 2018/6/14.
//  Copyright © 2018年 allen. All rights reserved.
//

import UIKit
import SwiftyJSON

enum RequestOption {
    case cacheFrist, cacheUpdate
}

typealias Cache = RequestDataCache
class RequestDataCache: NSObject {
    static let sharedInstance = RequestDataCache()
    private override init() {
        cacheBox = [:]
        super.init()
        debugPrint("Cache.init")
    }
    deinit {
        debugPrint("Cache.deinit")
    }
    
    private var cacheBox: [String: JSON]
    func save(_ data: JSON, key: String) {
        guard !key.isEmpty else { return }
        cacheBox.updateValue(data, forKey: key)
        debugPrint("Cacae save to memory for \(key) success.")
    }
    
    func get(_ key: String) -> JSON? {
        return cacheBox[key]
    }
}
