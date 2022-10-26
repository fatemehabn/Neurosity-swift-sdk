import Foundation

public protocol RequestOperation {

    func build(url: URL, method: RequestMethod, data: [AnyHashable: Any]) -> URLRequest
    func parse(data: Data) -> RequestOperationResult
    
}

public enum RequestOperationResult {
    
    case error(Error)
    case okay([String: Any])
}

public class JSONRequestOperation: RequestOperation {
    
    internal var serialization: JSONSerialization.Type
    
    public init(serialization: JSONSerialization.Type) {
        self.serialization = serialization
    }
    
    public func build(url: URL, method: RequestMethod, data: [AnyHashable: Any]) -> URLRequest {
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "\(method)"
        
        if !data.isEmpty && method != .get {
            request.httpBody = try? serialization.data(withJSONObject: data, options: [])
        }
        
        return request
    }
    
    public func parse(data: Data) -> RequestOperationResult {
//        if serialization.isValidJSONObject(data) {
//            guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
//                return .error(RequestError.unparseableJSON)
//            }
//            
//            return .okay(jsonObject)
//        }
//        
//        guard let resultString = String(data: data, encoding: .utf8),
//            let resultStringData = resultString.data(using: .utf8) else {
//            return .error(RequestError.unparseableJSON)
//        }
//        
//        guard let jsonObject = try? JSONSerialization.jsonObject(with: resultStringData, options: []) as? [String: Any] else {
//            return .okay(resultString)
//        }
//
        do{
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
            return .okay(json!)
        }catch{ return .error(RequestError.unparseableJSON) }
            
        
    }
}

extension JSONRequestOperation {
    
    public class func create() -> JSONRequestOperation {
        let serialization = JSONSerialization.self
        let operation = JSONRequestOperation(serialization: serialization)
        return operation
    }
}
