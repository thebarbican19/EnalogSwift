//
//  Enalog Swift Client
//  Created by Joe Barbour for SprintDock (https://sprintdock.app) on 6/30/23.
//  In Collaboration with Enteka Software (hello@enalog.app)
//

import Foundation

#if os(macOS)
    import Cocoa
#else
    import UIKit
#endif

public enum EnalogDeviceInformationTypes {
    case model
    case os
    case type
    case architecture
    
}

public enum EnalogChannelType:String,Codable {
    case slack
    
}

public struct EnalogChannelObject:Codable {
    public var type:EnalogChannelType
    public var id:String
    
    public init(_ type: EnalogChannelType, id: String) {
        self.type = type
        self.id = id
        
    }
    
}

public struct EnalogCrashEvent:Codable {
    var event:String
    var channel:EnalogChannelObject?
    
}

public struct EnalogCrashObject:Codable {
    var name:String
    var reason:String?
   
    init(_ exception:NSException) {
        self.name = exception.name.rawValue
        self.reason = exception.reason
        
    }
    
}

public enum EnalogArchitectureType:String,Codable {
    case iOS = "iOS"
    case watchOS = "WatchOS"
    case macSilicon = "MacOS (Silicon)"
    case macIntel = "MacOS (Intel)"
    case visionOS = "VisionOS"
    case tvOS = "tvOS"
    
}

public enum EnalogDeviceType:String,Codable {
    case macbook
    case macbookPro
    case macbookAir
    case imac
    case macMini
    case macPro
    case macStudio
    case ipad
    case iphone
    case unknown
    
    var name:String {
        switch self {
            case .macbook: return "Macbook"
            case .macbookPro: return "Macbook Pro"
            case .macbookAir: return "Macbook Air"
            case .imac: return "iMac"
            case .ipad: return "iPad"
            case .iphone: return "iPhone"
            case .macMini: return "Mac Mini"
            case .macPro: return "Mac Pro"
            case .macStudio: return "Mac Pro"
            case .unknown: return "Unknown"
            
        }
        
    }
    
    static var model:String {
        #if os(macOS)
            var size = 0
            sysctlbyname("hw.model", nil, &size, nil, 0)
            var machine = [CChar](repeating: 0,  count: size)
            sysctlbyname("hw.model", &machine, &size, nil, 0)
            return String(cString: machine)

        #elseif os(iOS)
            var systemInfo = utsname()
            uname(&systemInfo)
            let machineMirror = Mirror(reflecting: systemInfo.machine)
            let identifier = machineMirror.children.reduce("") { identifier, element in
               guard let value = element.value as? Int8, value != 0 else { return identifier }
               return identifier + String(UnicodeScalar(UInt8(value)))
                
            }
        
            return identifier

        #endif
        
    }
    
    static var os:String {
        #if os(macOS)
            switch ProcessInfo().operatingSystemVersion.majorVersion {
                case 11 : return EnalogSystemName.bigsur.name
                case 12 : return EnalogSystemName.monterey.name
                case 13 : return EnalogSystemName.ventura.name
                case 14 : return EnalogSystemName.sonoma.name

                default :
                    switch ProcessInfo().operatingSystemVersion.minorVersion {
                        case 16 : return EnalogSystemName.mojave.name
                        case 17 : return EnalogSystemName.catalina.name
                        default : return EnalogSystemName.unknown.name
                        
                    }
                    
            }

        #elseif os(iOS)
            return "iOS \(ProcessInfo().operatingSystemVersion.majorVersion)"

        #elseif os(watchOS)
            return "watchOS \(ProcessInfo().operatingSystemVersion.majorVersion)"

        #elseif os(tvOS)
            return "tvOS \(ProcessInfo().operatingSystemVersion.majorVersion)"

        #elseif os(visionOS)
            return "visionOS \(ProcessInfo().operatingSystemVersion.majorVersion)"

        #else
            return ""

        #endif
        
    }
    
    static var type:EnalogDeviceType {
        #if os(macOS)
            let platform = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))

            if let model = IORegistryEntryCreateCFProperty(platform, "model" as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? Data {
                if let type = String(data: model, encoding: .utf8)?.cString(using: .utf8) {
                    if String(cString: type).lowercased().contains("macbookpro") { return .macbookPro }
                    else if String(cString: type).lowercased().contains("macbookair") { return .macbookAir }
                    else if String(cString: type).lowercased().contains("macbook") { return .macbook }
                    else if String(cString: type).lowercased().contains("imac") { return .imac }
                    else if String(cString: type).lowercased().contains("macmini") { return .macMini }
                    else if String(cString: type).lowercased().contains("macstudio") { return .macStudio }
                    else if String(cString: type).lowercased().contains("macpro") { return .macPro }
                    else { return .unknown }
                  
                }
              
            }

            IOObjectRelease(platform)
        
            return .unknown
        
        #elseif os(iOS)
            switch UIDevice.current.userInterfaceIdiom {
                case .phone:return .iphone
                case .pad:return .ipad
                default:return .unknown
                
            }

        #endif

    }
    
    static var architecture:EnalogArchitectureType {
        #if os(iOS)
            return .iOS
        
        #elseif os(tvOS)
            return .tvOS
        
        #elseif os(watchOS)
            return .watchOS
        
        #elseif os(visionOS)
            return .visionOS
        
        #elseif os(macOS)
            #if arch(arm64)
                return .macSilicon
        
            #elseif arch(x86_64)
                return .macIntel
        
            #endif
        #endif
        
    }
    
}

public enum EnalogSystemName:String,Codable {
    case mojave
    case catalina
    case bigsur
    case monterey
    case ventura
    case sonoma
    case unknown
    
    var name:String {
        switch self {
            case .mojave : return "Mojave"
            case .catalina : return "Catalina"
            case .bigsur : return "Big Sur"
            case .monterey : return "Monterey"
            case .ventura : return "Ventura"
            case .sonoma : return "Sonoma"
            default : return "Unknown"
            
        }
            
    }
    
}

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

public struct EnalogResponseDetails:Decodable {
    var msg:String
    var type:String
    
}

public struct EnalogResponse:Decodable {
    var message:String?
    var details:[EnalogResponseDetails]
    var enviroment:EnalogEnviroment?
        
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        self.message = try? values.decode(String.self, forKey: .message)
        self.enviroment = .production
        self.details = []
        
        if let details = try? values.decode([EnalogResponseDetails].self, forKey: .detail) {
            self.details = details
            
        }
        
        if let test = try? values.decode(Bool.self, forKey: .test) {
            if test == true {
                self.enviroment = .development
                
            }
            
        }
        
    }
    
    public enum CodingKeys: String, CodingKey {
        case message
        case test
        case detail

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

@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, visionOS 1.0, *)
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
    private var crash:EnalogCrashEvent?
    private var disabled:Bool = false

    public var debugger:Bool? = nil
    public var user = Dictionary<String,Encodable>()
    public var enviroment:EnalogEnviroment = .production
    
    init() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.requests = 0
            
        }
                
        #if DEBUG
            self.debug(true)
        
        #endif

    }
    
    public func debug(_ enabled:Bool, logType:EnalogErrors = .log) {
        self.debugger = enabled
        self.fatal = logType
        
    }
    
    public func disable(_ state:Bool = true) {
        self.disabled = state
        
    }
        
    public func crash<T: RawRepresentable>(_ event: T, channel:EnalogChannelObject? = nil) {
        if let event = event.rawValue as? String {
            self.crash = .init(event: event, channel: channel)
            
            NSSetUncaughtExceptionHandler(enalogCrash)
            
            self.engalogPending()

        }
        
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
        
        self.engalogPending()
        
    }
    
    public func ingest<T: RawRepresentable>(_ event: T?, description: String, metadata: Codable? = nil, tags: [String]? = nil, channel:EnalogChannelObject? = nil) where T.RawValue == String {
        guard let event = event?.rawValue as? String else {
            self.enalogLog("Event type does not exist", status: 422)
            return

        }
        
        if self.disabled == false {
            self.ingest(event, description: description, metadata: metadata, tags: tags, channel: channel)
            
        }
    
    }
    
    private func ingest(_ event: String, description: String, metadata: Codable? = nil, tags: [String]? = nil, channel:EnalogChannelObject? = nil)  {
        var payload = Dictionary<String, EnalogEncodableValue>()
        payload["name"] = EnalogEncodableValue(event)
        payload["description"] = EnalogEncodableValue(description)
        payload["tags"] = EnalogEncodableValue(self.enaglogTagsMerge(tags))
        
        if let project = self.enalogProject {
            payload["project"] = EnalogEncodableValue(project)
            
        }
        
        if let user = self.user["UserID"] {
            payload["user_id"] = EnalogEncodableValue(user)
            
        }
        
        if let channel = channel {
            var object: [String: EnalogEncodableValue] = [:]
            object[channel.type.rawValue] = EnalogEncodableValue(channel.id)

            payload["channels"] = EnalogEncodableValue(object)
            
        }
        
        if let metadata = metadata {
            do {
                let convert = try JSONEncoder().encode(metadata)
                let object = try JSONSerialization.jsonObject(with: convert, options: [])
                
                if let dictionary = object as? [String: String] {
                    payload["meta"] = EnalogEncodableValue(self.enaglogMetadataMerge(dictionary))
                    
                }
                else if let dictionary = object as? [String: Codable] {
                    payload["meta"] = EnalogEncodableValue(self.enaglogMetadataMerge(dictionary))
                    
                }
                else {
                    print("CODABLE OBJECTY" ,object)
                    self.enalogLog("Metadata does not conform to the Codable Protocol", status: 400)
                    
                }
                
            }
            catch {
                self.enalogLog("Metadata Encoding Error '\(error.localizedDescription)'", status: 400)

            }
            
        }
        else {
            payload["meta"] = EnalogEncodableValue(self.enaglogMetadataMerge(nil))
            
        }
        
        self.enalogCallback(object: payload)
        
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
    
    private func enalogRequestBuild(object:Dictionary<String,EnalogEncodableValue>) -> URLRequest? {
        if self.requests < self.throttle {
            if let endpoint = URL(string: "https://api.enalog.app/v1/events"), let appkey = EnalogManager.key {
                do {
                    let payload = try JSONEncoder().encode(object)
                    
                    var request = URLRequest(url: endpoint, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60)
                    request.httpMethod = "POST"
                    request.httpBody = payload
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.addValue("Bearer \(appkey)", forHTTPHeaderField: "Authorization")
                    
                    if self.debugger == true {
                        print("\n\n✅ Enalog Client - Payload Sent:" ,String(decoding: payload, as: UTF8.self))
                        
                    }
                    
                    return request
                    
                }
                catch {
                    self.enalogLog("Enalog Ingest Codable Error: \(error)", status: 500)
                    
                }
                
            }
            
        }
        else {
            self.enalogLog("Enalog Ingest Error: Requests Throttled (\(self.requests)/\(self.throttle))", status: 429)
            
        }
        
        return nil
        
    }

    private func enalogCallback(object:Dictionary<String,EnalogEncodableValue>)  {
        do {
            if let request = self.enalogRequestBuild(object: object) {
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    guard let data = data else {
                        return
                        
                    }
                    
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
                        
                        UserDefaults.standard.removeObject(forKey: "enalog.ingest.crash")
                        
                    }
                    
                    self.requests += 1
                    
                }
                
                task.resume()
                
            }
                        
        }
        
    }
    
    private func enaglogTagsMerge(_ tags: [String]?) -> Array<EnalogEncodableValue> {
        var combined: Array<EnalogEncodableValue> = []

        for (_, value) in self.enalogSystem() {
            combined.append(EnalogEncodableValue(value))
            
        }
        
        if let tags = tags {
            for tag in tags {
                combined.append(EnalogEncodableValue(tag))
                
            }
            
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
            payload["Version"] = "v\(version)"

        }
        
        payload["Architecture"] = EnalogDeviceType.architecture.rawValue
        payload["Model"] = EnalogDeviceType.model
        payload["OS"] = EnalogDeviceType.os
        payload["Device"] = EnalogDeviceType.type.name

        if (UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light") == "Light" {
            payload["Theme"] = "Light Mode"
            
        }
        else {
            payload["Theme"] = "Dark Mode"

        }
        
        if let locale = Locale.current.regionCode?.uppercased() {
            payload["Locale"] = locale

        }

        return payload
        
    }
    
    private func engalogPending() {
        if let report = UserDefaults.standard.string(forKey: "enalog.ingest.crash"), let event = self.crash {
            if let object = try? JSONDecoder().decode(EnalogCrashObject.self, from: Data(report.utf8)) {
                
                self.ingest(event.event, description: "Crash Detected \(object.name)", metadata: object, channel: self.crash?.channel)
                
                self.enalogLog("Crash Previously Detected '\(object.name)'", status: 500)
                
            }
                        
        }
        
    }
    
    private func enalogLog(_ text:String, status:Int) {
        if self.debugger == true {
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
    
    private var enalogDeviceType:EnalogDeviceType {
        #if os(macOS)
            let platform = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))

            if let model = IORegistryEntryCreateCFProperty(platform, "model" as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? Data {
                if let type = String(data: model, encoding: .utf8)?.cString(using: .utf8) {
                    if String(cString: type).lowercased().contains("macbookpro") { return .macbookPro }
                    else if String(cString: type).lowercased().contains("macbookair") { return .macbookAir }
                    else if String(cString: type).lowercased().contains("macbook") { return .macbook }
                    else if String(cString: type).lowercased().contains("imac") { return .imac }
                    else if String(cString: type).lowercased().contains("macmini") { return .macMini }
                    else if String(cString: type).lowercased().contains("macstudio") { return .macStudio }
                    else if String(cString: type).lowercased().contains("macpro") { return .macPro }
                    else { return .unknown }
                    
                }
                
            }

            IOObjectRelease(platform)
        
        #endif
        
        return .unknown
        
    }
        
}

public func enalogCrash(exception: NSException) {
    let object:EnalogCrashObject = .init(exception)
    
    if let encoded = try? JSONEncoder().encode(object) {
        UserDefaults.standard.set(String(decoding: encoded, as: UTF8.self), forKey: "enalog.ingest.crash")
        UserDefaults().synchronize()

    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        abort()
        
    }

}
