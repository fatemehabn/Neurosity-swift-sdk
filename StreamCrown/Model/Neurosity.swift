import Foundation



class Neurositysdk{
    public var firebase: Firebaseios
    public var deviceID: String
    public var baseURL: String
    public var apiKey: String
    public var token: String?
    public var subscriptionIDs: [String]
    public var clientID:String?
    internal var lastPushTime: Int
    internal var lastRandChars: [Int]
    

    
    init(options:[String:String]){
        self.baseURL = options["baseURL"]!
        self.apiKey = options["apiKey"]!
        self.firebase = Firebaseios.create(baseURL: options["baseURL"]!, apiKey: options["apiKey"]!)
        self.deviceID = options["deviceID"]!
        self.token =  nil
        self.lastRandChars = [Int]()
        self.lastPushTime = 0
        self.clientID = nil
        self.subscriptionIDs = [String]()
//        atexit.register(self.exit_handler)
    }

    func exit_handler() async throws{
        try await self.remove_client()
        try await self.remove_all_subscriptions()
    }

    func get_server_timestamp() -> [String:String]{
        return [".sv": "timestamp"]
    }
    
    func login(credentials:[String:String]) async throws
    {
        if (self.token != nil){
                print("Neurosity SDK: The SDK is already authenticated.")
                return
        }
        self.token = try await self.firebase.sign_in_with_email_and_password(
            email:credentials["email"]!, password:credentials["password"]!)
            
        if (self.clientID != nil){
            return
        }
        else{
            
            try await self.add_client()

        }
            
    }

    
    func add_client() async throws{
        let clientsPath = "devices/\(self.deviceID)/clients"
        let timestamp = self.get_server_timestamp()
//        _ = try await firebase.post(path: clientsPath, value: timestamp){ result in
//            switch result {
//            case .failed(let error):
//                print(error)
//                // Do some stuff
//
//            case .succeeded(let data):
//                   print(type(of: data))
//                    if let data = data as? Dictionary<String, AnyObject>, let clientID = data["name"] as? String {
//                                        // do stuff
//                        self.clientID = clientID
//
//                    }
//                print("ClientID")
//                print(self.clientID)
//
//            }
//        }
    }

    func remove_client() async throws{
        if let client_id = self.clientID{
            let clientsPath = "devices/\(self.deviceID)/clients/\(client_id)"
            let data = try await firebase.delete(path: clientsPath)
            
        }
    }

    func generate_key()->String{
         
        let pushChars = ["-", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "_", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
        var now = Int(Date().timeIntervalSinceReferenceDate * 1000)
        let duplicateTime = now == self.lastPushTime
        self.lastPushTime = now
        var newID = ""
//        var timeStampChars = ["0", "0", "0", "0", "0", "0", "0", "0"]
        for i in 0...7{
            newID += pushChars[now % 64]
            now = Int(floor(Double(now) / Double(64)))
        }
        
        newID = String(newID.reversed())
        
       
        
        if !duplicateTime{
            for _ in 0...11{
                self.lastRandChars.append(
                    Int(floor(Double.random(in: 0 ..< 1) * Double(64))))
            }
        }
        else{
            for i in 0...10{
                if self.lastRandChars[i] == 63{
                        self.lastRandChars[i] = 0
                }
                self.lastRandChars[i] += 1
            }
        }
        for i in 0...11{
                newID += pushChars[self.lastRandChars[i]]
        }
        return newID
    }

    func add_subscription(metric: String, label:String, atomic:Bool) async throws -> String {
        let subscriptionID = self.generate_key()
        let subscriptionPath = "devices/\(self.deviceID)/subscriptions/\(subscriptionID)"

        let subscriptionPayload = [
            "atomic": atomic,
            "clientId": self.clientID!,
            "id": subscriptionID,
            "labels": [label],
            "metric": metric,
            "serverType": "firebase",
        ] as [String : Any] as [String : Any]

        let data = try await firebase.put(path: subscriptionPath, value: subscriptionPayload)
        self.subscriptionIDs.append(subscriptionID)
        return subscriptionID
    }

    func remove_subscription(subscriptionID:String) async throws{
        let subscriptionPath = "devices/\(self.deviceID)/subscriptions/\(subscriptionID)"
        try await firebase.delete(path: subscriptionPath)
    }
    func remove_all_subscriptions() async throws {
        let subscriptionsPath = "devices/\(self.deviceID)/subscriptions"
        var data = [String:Any]()

        for subscriptionID in self.subscriptionIDs{
            data[subscriptionID] = nil
        }
        _ = try await firebase.patch(path: subscriptionsPath, value: data)
    }

    func stream_metric(metric:String, label:String, atomic:Bool, completion: @escaping (String?) -> Void){
        var metricPath: String
//        let subscriptionID = try await self.add_subscription(metric:metric, label:label, atomic:atomic)
//        print("subscriptionID:", subscriptionID)
        if (atomic){
            metricPath = "metrics/\(metric)"
        }
        else{
            metricPath = "metrics/\(metric)/\(label)"
        }

//        func teardown(subscriptionID:String){
//            self.remove_subscription(subscriptionID :subscriptionID)
//            if let index = subscriptionIDs.firstIndex(of: subscriptionID) {
//                subscriptionIDs.remove(at: index)
//            }
//        }
//        print("metricPath:", metricPath)
       stream_from_path(pathName:metricPath, completion: completion)

    }

    func stream_from_path(pathName:String, completion: @escaping (String?) -> Void)  {
//        let path = "devices/\(deviceID)/\(pathName)"
//        print("path")
//        print(pathName)
        let path = "\(self.baseURL)/devices/\(deviceID)/\(pathName).json?auth=\(self.token!)"
//        print("path:", path)
        let url = URL(string: path)
//        print("url:", url)
        let eventSource: EventSource = EventSource(url: url!)

        
        eventSource.onOpen { [weak self] in
                    print("connected")
                }

                
        eventSource.onComplete { [weak self] statusCode, reconnect, error in
                    print("completed")
                    let retryTime = eventSource.retryTime ?? 3000
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(retryTime)) { [weak self] in
                        eventSource.connect()
                    }
                }

                
        eventSource.onMessage { [weak self] id, event, data in
            print("hi")
                }

        
        eventSource.addEventListener("put") { [weak self] id, event, data in
            
                }
        eventSource.connect()
        
    }


    func get_from_path(pathName:String) async throws -> [String: Any]{
        let path="devices/\(self.deviceID)/\(pathName)"
        let data = try await firebase.get(path: path, query: [:])
        let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any ]
        return json
    }


    func brainwaves_raw(completion: @escaping (String?) -> Void) {
        self.stream_metric(metric:"brainwaves", label:"raw", atomic:false, completion: completion)
    }
        
    func brainwaves_raw_unfiltered(completion: @escaping (String?) -> Void){
        self.stream_metric(metric:"brainwaves", label:"rawUnfiltered", atomic:false, completion: completion)
    }

    func brainwaves_psd(completion: @escaping (String?) -> Void){
        self.stream_metric(metric:"brainwaves", label:"psd", atomic:false, completion: completion)
    }
    func brainwaves_power_by_band(completion: @escaping (String?) -> Void) {
        self.stream_metric(metric:"brainwaves", label:"powerByBand", atomic:false, completion: completion)
    }
    
//    func signal_quality(callback:@escaping (RequestResult) -> Void){
//        return self.stream_metric(callback:callback, metric:"signalQuality", label:nil, atomic:true)
//    }
//
//    func accelerometer(callback:@escaping (RequestResult) -> Void){
//        return self.stream_metric(callback:callback, metric:"accelerometer", label:nil, atomic:true)
//    }
    func calm(completion: @escaping (String?) -> Void) async throws {
        self.stream_metric(metric :"awareness", label:"calm", atomic:false, completion: completion)
    }
    func focus(completion: @escaping (String?) -> Void)
    {
        self.stream_metric(metric:"awareness", label:"focus", atomic: false, completion: completion)
    }

    func kinesis(label:String, completion: @escaping (String?) -> Void)
    {
        self.stream_metric(metric:"kinesis", label:label, atomic:false, completion: completion)
    }
    
    func kinesis_predictions(label:String,completion: @escaping (String?) -> Void){
        self.stream_metric(metric: "predictions", label:label, atomic: false, completion: completion)
    }
    
    func status(completion: @escaping (String?) -> Void) async throws{
        self.stream_from_path(pathName:"status", completion: completion)
    }

    func settings(completion: @escaping (String?) -> Void){
        self.stream_from_path(pathName: "settings", completion: completion)
    }

    func status_once() async throws -> [String:Any]{
        return try await self.get_from_path(pathName: "status")
    }

    func settings_once() async throws -> [String:Any]{
        return try await self.get_from_path(pathName: "settings")
    }
    func get_info() async throws -> [String:Any]{
        return try await self.get_from_path(pathName:"info")
    }
}


extension String {
    func toJSON() -> Any? {
        guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
    }
}
