import Foundation

public class Firebaseios {
    
    internal var request: RequestProtocol
    public var apiKey: String
    public var baseURL: String
    public var token:String?
    
    public init(request: RequestProtocol, baseURL: String, apiKey: String) {
        self.request = request
        self.apiKey = apiKey
        self.baseURL = baseURL
    }
    
            
    public func sign_in_with_email_and_password(email: String, password: String) async throws -> String
    {
        let authpath = "https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=\(self.apiKey)"
        let _ = ["email": email, "password": password, "returnSecureToken": true] as [String : Any]
        let data = try await self.request.write(path: authpath, method: .post, data: ["email": email, "password": password, "returnSecureToken": true])
        print(data)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        if let json = json as? Dictionary<String, AnyObject>, let tokenID = json["idToken"] as? String {
                                        // do stuff
            self.token = tokenID
            return tokenID
                // Do some stuff
          
        }
        return ""
        
    }
    
    
    
    public func get(path relativePath: String, query: [AnyHashable: Any]) async throws -> Data
    {
        let path = RequestPath(baseURL: self.baseURL, accessToken: token!)
        return try await self.request.read(path: path.build(relativePath), query: query)
    }
    
    
    public func put(path relativePath: String, value: [AnyHashable: Any]) async throws -> Data
    {
        let path = RequestPath(baseURL: baseURL, accessToken: token!)
        return try await self.request.write(path: path.build(relativePath), method: .put, data: value)
    }
    
    public func post(path relativePath: String, value: [AnyHashable: Any])  async throws -> Data
    {
        let path = RequestPath(baseURL: baseURL, accessToken: token!)
        return try await self.request.write(path: path.build(relativePath), method: .post, data: value)
    }
    
    public func patch(path relativePath: String, value: [AnyHashable: Any]) async throws -> Data{
        let path = RequestPath(baseURL: baseURL, accessToken: token!)
        return try await self.request.write(path: path.build(relativePath), method: .patch, data: value)
    }
    
    public func delete(path relativePath: String) async throws -> Data {
        let path = RequestPath(baseURL: baseURL, accessToken: token!)
        return try await self.request.delete(path: path.build(relativePath))
    }
    
    
    
    
}

extension Firebaseios{
    
    public class func create(baseURL: String, apiKey: String) -> Firebaseios {
        let request = Request.create()
        let pyrobase = Firebaseios(request: request, baseURL: baseURL, apiKey: apiKey)
        return pyrobase
    }
   
}



