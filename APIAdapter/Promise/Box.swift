//
//  Box.swift
//  APIAdapter
//
//  Created by kayla.wen on 2018/9/28.
//  Copyright © 2018年 kayla.wen. All rights reserved.
//

import UIKit

//
class Handlers<R> {
    var bodies: [(R) -> Void] = []
    func append(_ item: @escaping(R) -> Void) { bodies.append(item) }
}


class Box<T> {
    // 檢查
    func inspect() -> Sealant<T> { fatalError() }
    func inspect(_: (Sealant<T>) -> Void) { fatalError() }
    // 封裝
    func seal(_: T) {}
}
// 密封盒
class SealedBox<T>: Box<T> {
    let value: T
    init(value: T) {
        self.value = value
    }
    override func inspect() -> Sealant<T> {
        return .resolved(value)
    }
}
// 密封材料
enum Sealant<R> {
    case pending(Handlers<R>)
    case resolved(R)
}
//
class PandoraBox<T>: Box<T> {
    /*
     默認狀態為 .pending ，handlers 中的 bodies 為空
     */
    private var sealant = Sealant<T>.pending(Handlers())
    /*
     創建并发的队列用来读写一个数据对象。
     */
    private lazy var _queue: DispatchQueue = {
        return DispatchQueue(label: "com.promise.apiadapter.barrier", attributes: .concurrent)
    }()
    
    // ??? 是要檢查什麼？
    override func inspect() -> Sealant<T> {
        var _sealant: Sealant<T>! // MARK 不懂 ! 在這裡的意思
        // Variable '_sealant' captured by a closure before being initialized
        _queue.sync {
            _sealant = self.sealant
        }
        return _sealant
    }
    
    override func seal(_ value: T) {
        var handlers: Handlers<T>!
        /*
         如果这个队列里的操作是读的，那么可以多个同时进行。如果有写的操作，则必须保证在执行写入操作时，不会有读取操作在执行，必须等待写入完成后才能读取，否则就可能会出现读到的数据不对。
         */
        _queue.sync(flags: .barrier) {
            guard case .pending(let _handlers) = self.sealant else {
                return // already fulfilled!
            }
            handlers = _handlers
            self.sealant = .resolved(value)
        }
        
        if let handlers = handlers {
            handlers.bodies.forEach { (task) in
                task(value) // ???
            }
        }
    }
}
