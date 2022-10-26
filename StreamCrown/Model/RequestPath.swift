import Foundation

public protocol RequestPathProtocol {

    var baseURL: String { get }
        
    func build(_ path: String) -> String
}

public class RequestPath: RequestPathProtocol {
    
    internal var accessToken: String
    
    public var baseURL: String
    
    public init(baseURL: String, accessToken: String) {
        self.baseURL = baseURL
        self.accessToken = accessToken
    }
    
    public func build(_ path: String) -> String {
        guard !baseURL.isEmpty else {
            return ""
        }
        
        return "\(baseURL)/\(path).json?auth=\(accessToken)"
    }
}
