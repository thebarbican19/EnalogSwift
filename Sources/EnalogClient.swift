//
//  Enalog Swift Client
//  Created by Joe Barbour for SprintDock (https://sprintdock.app) on 6/30/23.
//  In Collaboration with Enteka Software (hello@enalog.app)
//

import Foundation

public enum EnalogEnviroment {
    case development
    case production
    
    var testing:Bool {
        switch self {
            case .development : return true
            case .production : return false
            
        }
        
    }
    
}

public enum EnalogErrors {
    case none
    case fatal
    case log
    
}

public struct EnalogResponse:Decodable {
    var message:String?
    var enviroment:EnalogEnviroment?
        
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        self.message = try! values.decode(String.self, forKey: .message)
        self.enviroment = .production
        
        if let test = try? values.decode(Bool.self, forKey: .test) {
            if test == true {
                self.enviroment = .development
                
            }
            
        }
        
    }
    
    public enum CodingKeys: String, CodingKey {
        case message
        case test

    }
    
}

public struct EnalogEncodableValue: Encodable {
    let value: Encodable
    
    public func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
        
    }
    
    init(_ value: Encodable) {
        self.value = value
        
    }
    
}

@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *)
public class EnalogManager {
    public static let main = EnalogManager()
    
    public static var key:String? {
        if let appkey = Bundle.main.infoDictionary?["EN_API_KEY"] as? String  {
            return appkey
            
        }
        
        return nil
        
    }
    
    private var fatal:EnalogErrors = .none
    private var project:String?
    private var requests:Int = 0
    private var throttle:Int = 10
    
    public var debugger:Bool = false
    public var user = Dictionary<String,Encodable>()
    public var enviroment:EnalogEnviroment = .production
    
    init() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.requests = 0
            
        }
        
    }
    
    public func debug(_ enabled:Bool, logType:EnalogErrors = .log) {
        self.debugger = enabled
        self.fatal = logType
        
    }

    public func throttle(perMinute limit:Int) {
        if limit <= 20 {
            self.throttle = limit
            
        }
        
    }
    
    public func user(_ id:String, name:String? = nil, email:String? = nil, metadata:AnyObject? = nil) {
        if let name = name {
            self.user["Name"] = name
            
        }
        
        if let email = email {
            self.user["Email"] = email
            
        }
        
        self.user["UserID"] = id
        
        if let metadata = metadata as? Codable {
            do {
                let json = try JSONEncoder().encode(metadata)
                
                if let dictionary = try? JSONSerialization.jsonObject(with: json, options: []) as? [String: Encodable] {
                    for (key, value) in dictionary {
                        self.user[key.lowercased()] = value
                        
                    }
                    
                }
                
            }
            catch {
                self.enalogLog("Enalog Metadata Error: \(error)", status: 422)
                
            }
            
        }
        
    }
    
    public func ingest<T: RawRepresentable>(_ event: T, description: String, metadata: AnyObject? = nil, tags: [String]? = nil) where T.RawValue == String {
        var payload = Dictionary<String, EnalogEncodableValue>()
        payload["name"] = EnalogEncodableValue(event.rawValue)
        payload["description"] = EnalogEncodableValue(description)
        payload["tags"] = EnalogEncodableValue(self.enaglogTagsMerge(tags))
        
        if let project = self.enalogProject {
            payload["project"] = EnalogEncodableValue(project)
            
        }
        
        if let user = self.user["UserID"] {
            payload["user_id"] = EnalogEncodableValue(user)
            
        }
        
        if let metadata = metadata {
            if let metadata = metadata as? Dictionary<String,Encodable> {
                payload["meta"] = EnalogEncodableValue(self.enaglogMetadataMerge(metadata))
                
            }
            else {
                self.enalogLog("Metadata does not conform to the Codable Protocol", status: 400)
                
            }
            
        }
        else {
            payload["meta"] = EnalogEncodableValue(self.enaglogMetadataMerge(nil))
            
        }
        
        let unmuted = payload
        
        if #available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *) {
            Task(priority: .background) {
                await self.enalogCallback(object: unmuted)
                
            }
            
        }
        else {
            let version = ProcessInfo.processInfo.operatingSystemVersion
            let formatted = "\(version.majorVersion).\(version.minorVersion)"
            
            self.enalogLog("This system version (\(formatted)) is not supported.", status: 501)
            
        }
        
    }
    
    private var enalogProject:String? {
        if let project = Bundle.main.infoDictionary?["EN_PROJECT_NAME"] as? String  {
            return project.lowercased()
            
        }
        else if let project = Bundle.main.infoDictionary?["CFBundleName"] as? String  {
            return project.lowercased()
            
        }
        else {
            self.enalogLog("Enalog (EN_PROJECT_NAME) is Missing from info.plist.", status: 422)
            
        }
        
        return nil
        
    }
    
    @available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
    private func enalogCallback(object:Dictionary<String,EnalogEncodableValue>) async {
        if self.requests < self.throttle {
            if let endpoint = URL(string: "https://api.enalog.app/v1/events"), let appkey = EnalogManager.key {
                do {
                    let payload = try JSONEncoder().encode(object)
                    
                    var request = URLRequest(url: endpoint, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60)
                    request.httpMethod = "POST"
                    request.httpBody = payload
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.addValue("Bearer \(appkey)", forHTTPHeaderField: "Authorization")
                    
                    if self.debugger {
                        print("\n\n✅ Enalog Client - Payload Sent:" ,String(decoding: payload, as: UTF8.self))
                        
                    }
                    
                    do {
                        let (data, response) = try await URLSession.shared.data(for: request)
                        let object = try? JSONDecoder().decode(EnalogResponse.self, from: data)
                        
                        if let status = response as? HTTPURLResponse {
                            switch status.statusCode {
                            case 200 : self.enalogLog("Enalog Ingest Stored", status: status.statusCode)
                            case 401 : self.enalogLog("Enalog Authorization Error: API Key is Invalid", status: status.statusCode)
                            case 404 : self.enalogLog("Enalog Project '\(self.project ?? "")' does not exist. This can be specified by setting the  'EN_PROJECT_NAME' value in the info.plist.", status: status.statusCode)
                            default : self.enalogLog("Enalog Ingest Error: \(object?.message ?? "Unknown")", status: status.statusCode)
                                
                            }
                            
                            if let enviroment = object?.enviroment {
                                self.enviroment = enviroment

                            }
                                                        
                        }
                        
                    }
                    catch {
                        self.enalogLog("Enalog Ingest Error: \(error)", status: 500)
                        
                    }
                    
                    self.requests += 1
                    
                }
                catch {
                    self.enalogLog("Enalog Ingest Codable Error: \(error)", status: 500)
                    
                }
                
            }
            
        }
        else {
            self.enalogLog("Enalog Ingest Error: Requests Throttled (\(self.requests)/\(self.throttle))", status: 429)
            
        }
        
    }
    
    private func enaglogTagsMerge(_ tags: [String]) -> Array<EnalogEncodableValue> {
        var combined: Array<EnalogEncodableValue> = []

        for (_, value) in self.enalogSystem() {
            combined.append(EnalogEncodableValue(value))
            
        }
        
        for tag in tags {
            combined.append(EnalogEncodableValue(tag))
            
        }
        
        return combined
        
    }
    
    private func enaglogMetadataMerge(_ metadata: Dictionary<String, Encodable>?) -> Dictionary<String, EnalogEncodableValue> {
        var combined: [String: EnalogEncodableValue] = [:]

        for (key, value) in self.user {
            combined[key] = EnalogEncodableValue(value)
            
        }

        if let metadata = metadata {
            for (key, value) in metadata {
                combined[key] = EnalogEncodableValue(value)
            }
            
        }
        
        return combined

    }
    
    private func enalogSystem() -> Dictionary<String,Encodable> {
        var payload = Dictionary<String,Encodable>()

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            payload["Version"] = version

        }
        
        #if os(iOS)
            payload["Architecture"] = "iOS"
        #elseif os(tvOS)
            payload["Architecture"] = "tvOS"
        #elseif os(watchOS)
            payload["Architecture"] = "watchOS"
        #elseif os(macOS)
            #if arch(arm64)
                payload["Architecture"] = "macOS (Silicon)"
            #elseif arch(x86_64)
                payload["Architecture"] = "macOS (Intel)"
            #endif
        #endif
        
        payload["Theme"] = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
        
        print("Tags: " ,payload)
        
        return payload
        
    }
    
    private func enalogLog(_ text:String, status:Int) {
        if self.debugger {
            if status == 200 || status == 201 {
                print("\n\n✅ Enalog Client \(self.enviroment.testing ? "Testing":"") - \(text)\n\n")
    
            }
            else {
                switch fatal {
                    case .fatal: fatalError("\n\n🚨 Enalog Client \(self.enviroment.testing ? "Testing":"") - \(status) - \(text)")
                    case .log: print("\n\n🚨 Enalog Client \(self.enviroment.testing ? "Testing":"") - \(status) \(text)\n\n")
                    default : break
                    
                }
                
            }
            
        }
        
    }
    
}
