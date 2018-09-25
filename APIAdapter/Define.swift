//
//  Define.swift
//  APIAdapter
//
//  Created by kayla.wen on 2018/6/22.
//  Copyright © 2018年 kayla.wen. All rights reserved.
//

import UIKit

enum log {
    case ln(String)
    case url(String)
    case api(String)
    case obj(Any)
    case error(Any)
}
postfix operator /
postfix func / (target: log) {
    switch target {
    case .ln(let line):
        logPrint(emoji: "", line)
        
    case .url(let url):
        logPrint(emoji: "👻", url)
        
    case .api(let str):
        logPrint(emoji: "📂", str)
        
    case .obj(let obj):
        if let obj = obj as? [String: Any] {
            let jsonData = try! JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                logPrint(emoji: "📦", jsonString)
            }
        } else {
            logPrint(emoji: "📦", obj)
        }
        
    case .error(let error):
        if let error = error as? [String: Any] {
            let jsonData = try! JSONSerialization.data(withJSONObject: error, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                logPrint(emoji: "🛑", jsonString)
            }
        } else {
            logPrint(emoji: "🛑", error)
        }
    }
}

private func logPrint<T>(emoji: String, _ object: T) {
    if emoji.isEmpty {
        debugPrint("\(object)")
    } else {
        debugPrint("\(emoji) \(object)")
    }
}
