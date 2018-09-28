//
//  ViewController.swift
//  APIAdapter
//
//  Created by kayla.wen on 2018/6/22.
//  Copyright © 2018年 kayla.wen. All rights reserved.
//

import UIKit
import SwiftyJSON
import PromiseKit

enum MyError: Error {
    case reject
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        API.shared.logDisable()
        delay(1.0)
            .then { _ in
                self.fetch()
            }.then { (str) -> Promise<String> in
                debugPrint("fetch 1 > ")
                debugPrint(str)
                debugPrint("then")
                return self.fetch2()
            }.done { (str) in
                debugPrint("fetch 2 > ")
                debugPrint(str)
                debugPrint("done")
            }.catch { (error) in
                debugPrint(error)
        }

        debugPrint("123")
    }
    
    func delay(_ delay: TimeInterval) -> Promise<Void> {
        debugPrint("delay")
        return Promise { seal in
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                debugPrint("daley after")
                seal.fulfill(())
            })
        }
    }

    func fetch() -> Promise<String> {
        debugPrint("fetch 1")
        return Promise { seal in
            debugPrint("call api 1")
            API.shared.request([Model.self], target: TestAPI.getdata) { (result) in
                // callback
                debugPrint("api callback 1")
                switch result {
                case .success(_):
                    seal.fulfill("ya 1")
                    
                case .fail(_):
                    seal.reject(MyError.reject)
                }
            }
        }
    }
    
    func fetch2() -> Promise<String> {
        debugPrint("fetch 2")
        return Promise { seal in
            debugPrint("call api 2")
            API.shared.request([Model.self], target: TestAPI.getdata) { (result) in
                // callback
                debugPrint("api callback 2")
                switch result {
                case .success(_):
                    seal.fulfill("ya 2")
                    
                case .fail(_):
                    seal.reject(MyError.reject)
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

class Model: ModelObject {
    var index: Int
    required init?(json: JSON) {
        self.index = 0
    }
}

import Moya
enum TestAPI: TargetType {
    case getdata
    case getdata2
}
extension TestAPI {
    var baseURL: URL {
        return URL(string: "https://www.google.com")!
    }
    
    var path: String {
        switch self {
        case .getdata:
            return ""
        case .getdata2:
            return "kayla"
        }
    }
    
    var method: Moya.Method {
        return .get
    }
    
    var sampleData: Data {
        return DataUtility.fileDataFromJSONFile(filename: "testdata")
    }
    
    var task: Task {
        return .requestCompositeData(bodyData: Data(), urlParameters: ["platform": 1])
    }
    
    var headers: [String : String]? {
        return [:]
    }
    
}

class DataUtility {
    static func fileDataFromJSONFile(filename: String, inDirectory subpath: String = "", bundle: Bundle = Bundle.main ) -> Data {
        guard let path = bundle.path(forResource: filename, ofType: "json", inDirectory: subpath) else { return Data() }
        
        if let dataString = try? String(contentsOfFile: path), let data = dataString.data(using: String.Encoding.utf8) {
            return data
        } else {
            return Data()
        }
    }
}
