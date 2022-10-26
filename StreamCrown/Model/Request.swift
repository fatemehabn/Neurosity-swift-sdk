import Foundation


public protocol RequestProtocol {
    
    func read(path: String, query: [AnyHashable: Any]) async throws -> Data
    func write(path: String, method: RequestMethod, data: [AnyHashable: Any]) async throws -> Data
    func delete(path: String) async throws -> Data
}

public class Request: RequestProtocol {
    
    
    
    internal var session: URLSession
    internal var operation: RequestOperation
    internal var response: RequestResponseProtocol
    
    public init(session: URLSession, operation: RequestOperation, response: RequestResponseProtocol) {
        self.session = session
        self.operation = operation
        self.response = response
    }
    
    public func read(path: String, query: [AnyHashable: Any]) async throws -> Data {
        return try await request(path, .get, query)
    }
    
    public func write(path: String, method: RequestMethod, data: [AnyHashable: Any]) async throws -> Data {
        return try await request(path, method, data)
    }
    
   
    
    public func delete(path: String) async throws -> Data {
        return try await request(path, .delete, [:])
    }
    
   
    
    
    internal func request(_ path: String, _ method: RequestMethod, _ data: [AnyHashable: Any]) async throws -> Data {
        
        
        
//        guard let url = buildURL(path, method, data) else {
//
//            return .failed(RequestError.invalidURL)
//        }
        let url = buildURL(path, method, data)
        
        let request = operation.build(url: url!, method: method, data: data)
//        let (data, _) = try await session.dataTask(with: request)
//        var res: RequestResult
        let (data, response) = try await session.data(for: request)
//        let (data, response) = try await URLSession.data(with: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            fatalError("Error while fetching data") }
//        let decodedData = try JSONDecoder().decode(Data.self, from: data)
        let result = self.operation.parse(data: data)
        
//        if let data = data as? Dictionary<String, AnyObject>, let tokenID = data["idToken"] as? String {
//                                        // do stuff
//            print("afarin khare")
//            print("khar")
////                    print(self.aToken)
//            print(data)
//                // Do some stuff
//
//        }
        
        
       
//        let task = session.dataTask(with: request) { data, response, error in
//            guard error == nil else {
//
//                res = .failed(error!)
//                return
//
//            }
//
//            guard response != nil else {
//                res = .failed(RequestError.invalidURL)
//                return
//            }
//
//            let error = self.response.isErroneous(response as? HTTPURLResponse, data: data)
//
//            guard error == nil else {
//                res = .failed(error!)
//                return
//            }
//
//            guard data != nil else {
//                res = .succeeded([:])
//                return
//            }
//
//            let result = self.operation.parse(data: data!)
//
//            switch result {
//            case .error(let info):
//               res = .failed(info)
//
//            case .okay(let info):
//                guard let okayInfo = info as? String, okayInfo.lowercased() == "null", method != .delete else {
//                    res = .succeeded(info)
//                    return
//                }
//
//                res = .failed(RequestError.nullJSON)
//            }
//        }
//        task.resume()
        return data
    }
    
    internal func buildURL(_ path: String, _ method: RequestMethod, _ data: [AnyHashable: Any]) -> URL? {
        switch method {
        case .get where !data.isEmpty:
            guard !path.isEmpty, var components = URLComponents(string: path) else {
                return nil
            }
            
            var queryItems = [URLQueryItem]()
            
            for (key, value) in data {
                let item = URLQueryItem(name: "\(key)", value: "\(value)")
                queryItems.insert(item, at: 0)
            }
            
            if components.queryItems != nil {
                components.queryItems!.append(contentsOf: queryItems)
                
            } else {
                components.queryItems = queryItems
            }
            
            return components.url
            
        default:
            return URL(string: path)
        }
    }
}

extension Request {
    
    public class func create() -> Request {
        let session = URLSession.shared
        let operation = JSONRequestOperation.create()
        let response = RequestResponse()
        let request = Request(session: session, operation: operation, response: response)
        return request
    }
}


