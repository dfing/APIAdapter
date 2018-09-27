//
//  Promise.swift
//  APIAdapter
//
//  Created by HSIAOJOU WEN on 2018/9/27.
//  Copyright © 2018年 kayla.wen. All rights reserved.
//

import UIKit

enum State<T> {
    case pending
    case fulfill(value: T)
    case rejected(Error)
}

class Promise<T> {
    typealias FulfillClosure = (T) -> Void
    typealias RejectClosure = (Int) -> Void
    typealias AsyncTask = (@escaping FulfillClosure, @escaping RejectClosure) -> Void
    
    let task: AsyncTask
    
    var fulfillClosure: FulfillClosure?
    var rejectClosure: RejectClosure?
    
    init(_ task: @escaping AsyncTask) {
        self.task = task
        debugPrint("init \(self)")
    }
    
    private func fulfill(result: T) {
        debugPrint(">")
        debugPrint("fulfill \(self)")
        debugPrint("fulfill \(result)")
        self.fulfillClosure?(result)
    }
    
    private func reject(error: Int) {
        debugPrint(">")
        debugPrint("reject \(self)")
        debugPrint("reject \(error)")
        self.rejectClosure?(error)
    }
    
    func success(closure: @escaping FulfillClosure) {
        debugPrint(">")
        debugPrint(self)
        debugPrint("success")
        self.fulfillClosure = closure
        debugPrint(">")
        debugPrint("task execute")
        debugPrint(self)
        self.task({ self.fulfill(result: $0) },
                  { self.reject(error: $0) })
    }
    
    func failed(closure: @escaping RejectClosure) {
        debugPrint(">")
        debugPrint(self)
        debugPrint("failed")
        self.rejectClosure = closure
    }
    
    func then<U>(f: @escaping (T) -> Promise<U>) -> Promise<U> {
        debugPrint(">")
        debugPrint("then")
        debugPrint(self)
        return Promise<U> { (resolve, reject) in
            self.task(
                // Resolve
                { (result) in
                    debugPrint(">")
                    debugPrint("wrapped")
                    debugPrint(self)
                    let wrapped = f(result)
                    wrapped.success { resolve($0) }
            }, // Reject
                { (error) in
                    debugPrint(">")
                    debugPrint("reject ..")
                    debugPrint(self)
                    reject(error)
            })
        }
    }
}
