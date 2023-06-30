//
//  Enalog Swift Client
//  Created by Joe Barbour for SprintDock (https://sprintdock.app) on 6/30/23.
//  In Collaboration with Enteka Software (hello@enalog.app)
//

import Foundation

enum EnalogErrors {
    case none
    case fatal
    case log
    
}

struct EnalogResponse:Codable {
    var detail:String?
    var id:String?
    
}

struct EnalogEncodableValue: Encodable {
    let value: Encodable
    
    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
        
    }
    
    init(_ value: Encodable) {
        self.value = value
        
    }
    
}

@available(iOS 13.0, *)
class EnalogManager {
    static var main = EnalogManager()
    
    private var debugger:Bool = false
    private var fatal:EnalogErrors = .none
    private var user = Dictionary<String,Encodable>()
    private var project:String?

    public func debug(_ enabled:Bool, logType:EnalogErrors = .log) {
        self.debugger = enabled
        self.fatal = logType
        
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
                        self.user[key.capitalized] = value
                        
                    }
                    
                }
  
            }
            catch {
                self.enalogLog("Enalog Metadata Error: \(error)", status: 422)

            }
            
        }

    }

    public func ingest(_ name:String, description:String, metadata:AnyObject? = nil, tags:[String]? = nil) {
        
        var payload = Dictionary<String, EnalogEncodableValue>()
        payload["name"] = EnalogEncodableValue(name)
        payload["description"] = EnalogEncodableValue(description)

        if let tags = tags {
            payload["tags"] = EnalogEncodableValue(tags)

        }
        
        if let project = self.enalogProject {
            payload["project"] = EnalogEncodableValue(project)

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
        
        Task(priority: .background) {
            await self.enalogCallback(object: unmuted)
            
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
    
    private var enalogKey:String? {
        if let appkey = Bundle.main.infoDictionary?["EN_API_KEY"] as? String  {
            self.enalogLog("enalog is READY!", status: 200)

            return appkey
            
        }
        else {
            self.enalogLog("enalog (EN_APP_KEY) is Missing from info.plist.", status: 422)
            
        }
        
        return nil
        
    }
    
    private func enalogCallback(object:Dictionary<String,EnalogEncodableValue>) async {
        if let endpoint = URL(string: "https://api.enalog.app/v1/events"), let key = self.enalogKey {
            do {
                let payload = try JSONEncoder().encode(object)

                var request = URLRequest(url: endpoint, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60)
                request.httpMethod = "POST"
                request.httpBody = payload
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
                
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
                            default : self.enalogLog("Enalog Ingest Error: \(object?.detail ?? "Unknown")", status: status.statusCode)
                            
                        }
                        
                    }
                    
                }
                catch {
                    self.enalogLog("Enalog Ingest Error: \(error)", status: 500)
                    
                }
                
            }
            catch {
                self.enalogLog("Enalog Ingest Codable Error: \(error)", status: 500)

            }
            
        }
        
    }
    
    private func enaglogMetadataMerge(_ metadata: Dictionary<String, Encodable>?) -> Dictionary<String, EnalogEncodableValue> {
        var combined: [String: EnalogEncodableValue] = [:]

        for (key, value) in self.user {
            combined[key] = EnalogEncodableValue(value)
            
        }
        
        for (key, value) in self.enalogSystem() {
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
        
        payload["Theme"] = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
        
        return payload
        
    }
    
    private func enalogLog(_ text:String, status:Int) {
        if self.debugger {
            if status == 200 || status == 201 {
                print("\n\n✅ Enalog Client - \(text)\n\n")
    
            }
            else {
                switch fatal {
                    case .fatal: fatalError("\n\n🚨 Enalog Client - \(status) - \(text)")
                    case .log: print("\n\n🚨 Enalog Client - \(status) \(text)\n\n")
                    default : break
                    
                }
                
            }
            
        }
        
    }
    
}
