//
//  APIHandler.swift
//  orange
//
//  Created by Ashley on 2017/5/23.
//  Copyright © 2017年 allen. All rights reserved.
//

import Foundation
import Moya
import SwiftyJSON
import Result

//enum APIKEY: String {
//    
//}

public class APIHandler: NSObject {
    // MARK: Shared Instance
    static let shared: APIHandler = APIHandler()
    private override init() {}
    private var serverCodeKey: String = "code"
    private var serverTimeKey: String = "time"
    private var responseDataKey: String = "data"
    private var responseMsgKey: String = "message"
    private let networkErrorCode = "0"
    
    func result<T: TargetType>(target: T, result: Result<Moya.Response, MoyaError>,
                               completeClosure: ((_ success: Bool, _ content: ResContent<JSON>?, _ error: ResError?) -> Void)?) {
        
        var content: ResContent<JSON>?
        var error: ResError?
        
        defer {
            log.obj(content)/
            log.error(error)/
        }
        
        let statusCode = result.value?.statusCode ?? 0
        guard let response = result.value?.data else {
            let error = self.handleRequestError(json: nil, statusCode: statusCode)
            completeClosure?(false, nil, error)
            return
        }
        let json = JSON(response)
        
        switch statusCode {
            
        case 200...299:
            let code = json[serverCodeKey].string ?? networkErrorCode
            let message = json[responseMsgKey].string ?? ""
            let data = json[responseDataKey]
            let time = json[serverTimeKey].int ?? 0
            content = ResContent<JSON>(statusCode: statusCode,
                                           code: code,
                                           msg: message,
                                           data: data,
                                           time: time)
            completeClosure?(true, content, nil)
            break
            
        default:
            error = self.handleRequestError(json: json, statusCode: statusCode)
            completeClosure?(false, nil, error)
            break
        }
    }
    
    func handleRequestError(json: JSON?, statusCode: Int?) -> ResError {
        let statusCode = statusCode ?? 0
        
        guard let json = json else {
            let error = ResError(statusCode: statusCode,
                                 code: "",
                                 msg: "json data error",
                                 data: nil,
                                 time: 0)
            return error
        }
        
        let serverCode = json[serverCodeKey].string ?? networkErrorCode
        var errMsg = String(describing: json[responseMsgKey])
        errMsg = self.errorMessage(errMsg, statusCode: statusCode, serverCode: serverCode)
        let data = json[responseDataKey]
        let time = json[serverTimeKey].int ?? 0
        let error = ResError(statusCode: statusCode, code: serverCode, msg: errMsg, data: data, time: time)
        return error
    }
    
    private func errorMessage(_ value: String, statusCode: Int, serverCode: String) -> String {
        var errMsg = value
        let servercode = serverCode
        #if DEBUG
            errMsg += "\n(debug:\(statusCode):\(servercode))"
        #endif
        return errMsg
    }
}
