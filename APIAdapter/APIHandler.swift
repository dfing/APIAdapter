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

public class APIHandler: NSObject {
    // MARK: Shared Instance
    static let shared: APIHandler = APIHandler()
    private override init() {}
    private let _serverCodeKey: String = "code"
    private let _serverTimeKey: String = "time"
    private let _responseDataKey: String = "data"
    private let _responseMsgKey: String = "message"
    private let _networkErrorCode = "0"
    // MARK: -
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
        let requestStatus: Bool
        let json = JSON(response)
        
        switch statusCode {
            
        case 200...299:
            requestStatus = true
            content = self.handleRequestContent(json, statusCode: statusCode)
            
        default:
            requestStatus = false
            error = self.handleRequestError(json: json, statusCode: statusCode)
        }
        
        completeClosure?(requestStatus, content, error)
    }
    // MARK: -
    private func handleRequestContent(_ json: JSON, statusCode: Int) -> ResContent<JSON> {
        let code = json[_serverCodeKey].string ?? _networkErrorCode
        let message = json[_responseMsgKey].string ?? ""
        let data = json[_responseDataKey]
        let time = json[_serverTimeKey].int ?? Int(Date().timeIntervalSince1970)
        return ResContent<JSON>(statusCode: statusCode,
                                code: code,
                                msg: message,
                                data: data,
                                time: time)
    }
    
    private func handleRequestError(json: JSON?, statusCode: Int) -> ResError {
        guard let json = json else {
            let error = ResError(statusCode: statusCode,
                                 code: "",
                                 msg: "json data error",
                                 data: nil,
                                 time: 0)
            return error
        }
        
        let serverCode = json[_serverCodeKey].string ?? _networkErrorCode
        var errMsg = String(describing: json[_responseMsgKey])
        errMsg = self.errorMessage(errMsg, statusCode: statusCode, serverCode: serverCode)
        let data = json[_responseDataKey]
        let time = json[_serverTimeKey].int ?? Int(Date().timeIntervalSince1970)
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
