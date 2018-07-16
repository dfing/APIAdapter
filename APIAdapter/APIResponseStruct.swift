//
//  APIResponseStruct.swift
//  APIAdapter
//
//  Created by kayla.wen on 2018/6/22.
//  Copyright © 2018年 kayla.wen. All rights reserved.
//

import UIKit
import SwiftyJSON

struct ResError {
    var statusCode: Int
    var code: String
    var msg: String
    var data: JSON?
    var time: Int
}

struct ResContent<T> {
    var statusCode: Int
    var code: String
    var msg: String
    var data: T?
    var time: Int
    
    static func create(for data: T?) -> ResContent {
        return ResContent(statusCode: 200, code: "0000", msg: "", data: data, time: Int(Date().timeIntervalSince1970))
    }
}
