//
//  ViewController.swift
//  APIAdapter
//
//  Created by kayla.wen on 2018/6/22.
//  Copyright © 2018年 kayla.wen. All rights reserved.
//

import UIKit
import SwiftyJSON

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        API.shared.request([Model.self], target: TestAPI.getdate) { (result) in
            switch result {
            case .success(let content):
                guard let data = content.data else { return }
            case .fail(_):
                break
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
    case getdate
}
extension TestAPI {
    var baseURL: URL {
        return URL(string: "")!
    }
    
    var path: String {
        return ""
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
