//
//  APIManager.swift
//  orange
//
//  Created by allen on 2017/1/19.
//  Copyright © 2017年 allen. All rights reserved.
//

import Foundation
import Moya
import Alamofire
import SwiftyJSON
import Result

protocol ModelObject {
    init?(json: JSON)
}
enum APIRequestResult<T, NetworkError> {
    case success(T)
    case fail(NetworkError)
} 

typealias API = APIManager
public class APIManager: NSObject {
	
	// MARK: Shared Instance
	static let sharedInstance: APIManager = APIManager()
    private override init() {}
	
	private final let alamofireManager: Alamofire.SessionManager = {
		let configuration = URLSessionConfiguration.default
		let manager = Alamofire.SessionManager(configuration: configuration)
		return manager
	}()
    
    // MARK: -
    @discardableResult
    final func request<T: TargetType>(target: T, options: [RequestOption] = [],
                                       loading: (() -> Void)? = nil,
                                       updated: ((APIRequestResult<ResContent<JSON>, ResError>) -> Void)? = nil,
                                       complete: ((APIRequestResult<ResContent<JSON>, ResError>) -> Void)?) -> Cancellable? {
        var first: Bool = true
        let closure: ((_ success: Bool, _ content: ResContent<JSON>?, _ err: ResError?) -> Void)? = { (success, content, error) in
            guard success, let content = content else {
                first ? complete?(.fail(error!)) : updated?(.fail(error!))
                first = false
                return
            }
            
            first ? complete?(.success(content)) : updated?(.success(content))
            first = false
        }
        return self.req(target: target, options: options, loading: loading, completeClosure: closure)
    }

    @discardableResult
    final func request<T: TargetType, MO: ModelObject>(_: MO.Type, target: T, options: [RequestOption] = [],
                                                        loading: (() -> Void)? = nil,
                                                        updated: ((APIRequestResult<ResContent<MO>, ResError>) -> Void)? = nil,
                                                        complete: ((APIRequestResult<ResContent<MO>, ResError>) -> Void)?) -> Cancellable? {
        var first: Bool = true
        let closure: ((_ success: Bool, _ content: ResContent<JSON>?, _ err: ResError?) -> Void)? = { (success, content, error) in
            guard success, let content = content, let data = content.data else {
                first ? complete?(.fail(error!)) : updated?(.fail(error!))
                first = false
                return
            }
            
            let model = MO(json: data)!
            let moContent = ResContent(statusCode: content.statusCode,
                                       code: content.code,
                                       msg: content.msg,
                                       data: model,
                                       time: content.time)
            first ? complete?(.success(moContent)) : updated?(.success(moContent))
            first = false
        }
        
        return self.req(target: target, options: options, loading: loading, completeClosure: closure)
    }
    
    @discardableResult
    final func requestArray<T: TargetType, MO: ModelObject>(_: MO.Type, target: T, options: [RequestOption] = [],
                                                             loading: (() -> Void)? = nil,
                                                             updated: ((APIRequestResult<ResContent<[MO]>, ResError>) -> Void)? = nil,
                                                             complete: ((APIRequestResult<ResContent<[MO]>, ResError>) -> Void)?) -> Cancellable? {
        var first: Bool = true
        let closure: ((_ success: Bool, _ content: ResContent<JSON>?, _ err: ResError?) -> Void)? = { (success, content, error) in
            guard success, let content = content, let data = content.data else {
                first ? complete?(.fail(error!)) : updated?(.fail(error!))
                first = false
                return
            }
            var array: [MO] = []
            if let data = data.array {
                data.forEach({ (json) in
                    array.append(MO(json: json)!)
                })
            }
            let moContent = ResContent(statusCode: content.statusCode,
                                       code: content.code,
                                       msg: content.msg,
                                       data: array,
                                       time: content.time)
            first ? complete?(.success(moContent)) : updated?(.success(moContent))
            first = false
        }
        return self.req(target: target, options: options, loading: loading, completeClosure: closure)
    }
}

extension APIManager {
    private final func req<T: TargetType>(target: T, options: [RequestOption],
                                           loading: (() -> Void)?,
                                           completeClosure: ((_ success: Bool, _ content: ResContent<JSON>?, _ err: ResError?) -> Void)?) -> Cancellable? {
        
        let key = target.path
        var needShowLoading: Bool = true
        if options.contains(.cacheFrist), let cacheData: JSON = Cache.sharedInstance.get(key) {
            log.ln("API response data from cache: \(key)")/
            needShowLoading = false
            completeClosure?(true, ResContent.create(for: cacheData), nil)
            if !options.contains(.cacheUpdate) { return nil }
        }
        
        if needShowLoading {
            DispatchQueue.main.async {
                loading?()
            }
        }
        
        let logstr = "(\(target.method)) \(String(describing: target.baseURL)+target.path)"
        log.url(logstr)/
        
        let provider = MoyaProvider<T>(endpointClosure: self.createEndpointxClosure(),
                                       stubClosure: MoyaProvider.neverStub,
                                       manager: self.alamofireManager,
                                       plugins: self.createPluginTypes())
        
        return provider.request(target) { result in
            log.url(target.path)/
            APIHandler.sharedInstance.result(target: target, result: result) { (success, content, error) in
                completeClosure?(success, content, error)
                if success, options.contains(.cacheUpdate), let data = content?.data {
                    Cache.sharedInstance.save(data, key: key)
                }
            }
        }
    }

    private final func createEndpointxClosure<T: TargetType>() -> ((T) -> Endpoint) {
        return { (target: T) -> Endpoint in
            var endpoint = MoyaProvider.defaultEndpointMapping(for: target)
            if let headers = target.headers {
                endpoint = endpoint.adding(newHTTPHeaderFields: headers)
            }
            log.api("Header: \(String(describing: endpoint.httpHeaderFields))")/
            return endpoint
        }
    }
    
    private final func createPluginTypes() -> [NetworkActivityPlugin] {
        let networkPlugin1 = NetworkActivityPlugin { (change, _) -> () in
            switch change {
            case .ended:
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
            case .began:
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
        }
        return [networkPlugin1]
    }
}

enum ParamKeyDefine: String {
    case JsonArrayParam = "jsonArray"
    case URLQueryParam = "urlQuery"
}

struct URLQueryBodyEncoding: Moya.ParameterEncoding {
    public static var `default`: URLQueryBodyEncoding { return URLQueryBodyEncoding() }
    
    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var req = try urlRequest.asURLRequest()
        if let query = parameters?[ParamKeyDefine.URLQueryParam.rawValue] as? [String: String] {
            var queryItems: [URLQueryItem] = []
            for (key, value) in query {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
            var components = URLComponents(string: req.url!.absoluteString)
            components?.queryItems = queryItems
            req.url = components?.url
        }
        
        if let body = parameters?[ParamKeyDefine.JsonArrayParam.rawValue] {
            let json = try JSONSerialization.data(withJSONObject: body, options: JSONSerialization.WritingOptions.prettyPrinted)
            req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            req.httpBody = json
        }
        
        return req
    }
}

extension Dictionary {
    var json: String {
        let invalidJson = "Not a valid JSON"
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            return String(bytes: jsonData, encoding: String.Encoding.utf8) ?? invalidJson
        } catch {
            return invalidJson
        }
    }
    
    func dict2json() -> String {
        return json
    }
}

public class APITestManager: APIManager {
    
}
