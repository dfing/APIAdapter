//
//  Promise.swift
//  APIAdapter
//
//  Created by HSIAOJOU WEN on 2018/9/27.
//  Copyright © 2018年 kayla.wen. All rights reserved.
//

import UIKit

enum Status<T> {
    case fulfilled(T)
    case rejected(Error)
}
/* Promise
 doSomething()
 .then( doAnotherThing )
 .then( doSomethingElse )
 .success( someHandler )
 */

protocol Thenable {
    associatedtype T
    var status: Status<T>? { get }
    func pipe(_: @escaping (Status<T>) -> Void)
}

extension Thenable { // 鏈
    func then<U: Thenable>(_ body: @escaping (T) -> U) -> Promise<U.T> {
        let _promise = Promise<U.T>()
        pipe { (status) in
            switch status {
            case .fulfilled(let value):
                let _sealant = body(value)
//                guard _sealant !== _promise else { return } // ???
                _sealant.pipe(_promise.box.seal)
                
            case .rejected(let error):
                _promise.box.seal(.rejected(error))
                
            }
        }
        return _promise
    }
}


class Promise<T>: Thenable {
    let box: Box<Status<T>>
    var status: Status<T>? {
        switch box.inspect() {
        case .pending:
            return nil
        case .resolved(let status):
            return status
        }
    }
    private init(box: SealedBox<Status<T>>) {
        self.box = box
    }
    init() {
        self.box = PandoraBox()
    }
    init<U: Thenable>(_ body: U) where U.T == T {
        self.box = PandoraBox()
        body.pipe(self.box.seal)
    }
    init(_ value: T) {
        self.box = SealedBox(value: .fulfilled(value))
    }
    public class func value(_ value: T) -> Promise<T> {
        return Promise(box: SealedBox(value: .fulfilled(value)))
    }
    
    func pipe(_ to: @escaping (Status<T>) -> Void) {
        switch self.box.inspect() {
        case .pending:
            self.box.inspect { _sealant in
                switch _sealant {
                case .pending(let handlers):
                    handlers.append(to)
                case .resolved(let value):
                    to(value)
                }
            }
        case .resolved(let value):
            to(value)
        }
    }
}

//class Promise<T> {
//    typealias FulfillClosure = (T) -> Void
//    typealias RejectClosure = (Int) -> Void
//    typealias AsyncTask = (@escaping FulfillClosure, @escaping RejectClosure) -> Void
//
//    let task: AsyncTask
//
//    var fulfillClosure: FulfillClosure?
//    var rejectClosure: RejectClosure?
//
//    init(_ task: @escaping AsyncTask) {
//        self.task = task
//        debugPrint("init \(self)")
//    }
//
//    private func fulfill(result: T) {
//        debugPrint(">")
//        debugPrint("fulfill \(self)")
//        debugPrint("fulfill \(result)")
//        self.fulfillClosure?(result)
//    }
//
//    private func reject(error: Int) {
//        debugPrint(">")
//        debugPrint("reject \(self)")
//        debugPrint("reject \(error)")
//        self.rejectClosure?(error)
//    }
//
//    // 响应结果并启动任务
//    func success(closure: @escaping FulfillClosure) {
//        debugPrint(">")
//        debugPrint(self)
//        debugPrint("success")
//        self.fulfillClosure = closure
//        debugPrint(">")
//        debugPrint("task execute")
//        debugPrint(self)
//        self.task({ self.fulfill(result: $0) }, // FulfillClosure
//                  { self.reject(error: $0) })   // RejectClosure
//    }
//
//    func failed(closure: @escaping RejectClosure) {
//        debugPrint(">")
//        debugPrint(self)
//        debugPrint("failed")
//        self.rejectClosure = closure
//    }
//
//    func then<U>(f: @escaping (T) -> Promise<U>) -> Promise<U> {
//        debugPrint(">")
//        debugPrint("then")
//        debugPrint(self)
//        return Promise<U> { (fulfill, reject) in
//            self.task(
//                // Resolve
//                { (result) in
//                    debugPrint(">")
//                    debugPrint("wrapped")
//                    debugPrint(self)
//                    let wrapped = f(result)
//                    wrapped.success { fulfill($0) }
//            }, // Reject
//                { (error) in
//                    debugPrint(">")
//                    debugPrint("reject ..")
//                    debugPrint(self)
//                    reject(error)
//            })
//        }
//    }
//}
