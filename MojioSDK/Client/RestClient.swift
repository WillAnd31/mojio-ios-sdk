/******************************************************************************
 * Moj.io Inc. CONFIDENTIAL
 * 2017 Copyright Moj.io Inc.
 * All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains, the property of
 * Moj.io Inc. and its suppliers, if any.  The intellectual and technical
 * concepts contained herein are proprietary to Moj.io Inc. and its suppliers
 * and may be covered by Patents, pending patents, and are protected by trade
 * secret or copyright law.
 *
 * Dissemination of this information or reproduction of this material is strictly
 * forbidden unless prior written permission is obtained from Moj.io Inc.
 *******************************************************************************/

import UIKit
import Alamofire
import SwiftyJSON
import ObjectMapper
import KeychainSwift

open class NextDone {}

open class ClientHeaders {
    open static let defaultRequestHeaders: [String:String] = {
        // Accept-Language HTTP Header; see https://tools.ietf.org/html/rfc7231#section-5.3.5
        let acceptLanguage = NSLocale.preferredLanguages.prefix(6).enumerated().map { index, languageCode in
            let quality = 1.0 - (Double(index) * 0.1)
            
            // Use language-region and language only combinations
            let languageSplit = languageCode.components(separatedBy: "-")
            if let language = languageSplit.first {
                return "\(languageCode),\(language);q=\(quality)"
            }
            else if languageSplit.count > 0 {
                return "\(languageCode);q=\(quality)"
            }
            else {
                return ""
            }
            
            }.joined(separator: ", ")
        
        return ["Accept-Language": acceptLanguage]
    }()
}

public enum RestClientEndpoint: String {
    case base = "/"
    case apps = "apps/"
    case secret = "secret/"
    case groups = "groups/"
    case users = "users/"
    case me = "me/"
    case history = "history/"
    case states = "states/"
    case locations = "locations/"
    case image = "image/"
    case mojios = "mojios/"
    case permission = "permission/"
    case permissions = "permissions/"
    case phoneNumbers = "phonenumbers/"
    case emails = "emails/"
    case tags = "tags/"
    case trips = "trips/"
    case vehicles = "vehicles/"
    case address = "address/"
    case vin = "vin/"
    case serviceSchedule = "serviceschedule/"
    case next = "next/"
    case activities = "activities/"
    case notificationSettings = "activities/settings/"
    case wifiRadio = "wifiradio/"
    case transactions = "transactions/"
    case geofences = "geofences/"
    case aggregates = "aggregates/"
    case statistics = "statistics/"
    case diagnosticCodes = "diagnosticcodes/"
    case polyline = "polyline/"
    
    // Storage
    // Parameters: Type, Id, Key
    // e.g. trips/{id}/store/{key}
    case storage = "%@%@/store/%@"
}

open class RestClient {
    
    fileprivate var requestMethod: Alamofire.HTTPMethod = .get

    open var pushUrl: String?
    open var requestUrl: String?
    open var requestV1Url: String?
    open var requestParams: [String:AnyObject] = [:]
    open var requestEntity: RestClientEndpoint = .base
    open var requestEntityId: String?
    // Default to global concurrent queue with default priority
    open static var defaultDispatchQueue = DispatchQueue.global()
    
    fileprivate var doNext: Bool = false
    fileprivate var nextUrl: String? = nil
    fileprivate var sinceBeforeFormatter = DateFormatter()
    fileprivate static let SinceBeforeDateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    fileprivate static let SinceBeforeTimezone = TimeZone(abbreviation: "UTC");
    fileprivate var dispatchQueue = RestClient.defaultDispatchQueue
    
    public init() {
        self.requestUrl = ClientEnvironment.SharedInstance.getApiEndpoint()
        self.requestV1Url = ClientEnvironment.SharedInstance.getV1ApiEndpoint();
        self.pushUrl = ClientEnvironment.SharedInstance.getPushWSEndpoint()

        self.sinceBeforeFormatter.dateFormat = RestClient.SinceBeforeDateFormat
        self.sinceBeforeFormatter.timeZone = RestClient.SinceBeforeTimezone
    }
    
    public convenience init(clientEnvironment: ClientEnvironment) {
        self.init()
        self.requestUrl = clientEnvironment.getApiEndpoint()
        self.requestV1Url = clientEnvironment.getV1ApiEndpoint()
        self.pushUrl = clientEnvironment.getPushWSEndpoint()
    }
    
    open func get() -> Self {
        self.requestMethod = .get
        return self
    }
    
    open func post() -> Self {
        self.requestMethod = .post
        return self
    }
    
    open func put() -> Self {
        self.requestMethod = .put
        return self
    }
    
    open func delete() -> Self {
        self.requestMethod = .delete
        return self
    }
    
    open func continueNext() -> Self {
        self.doNext = true
        return self
    }
    
    private func appendRequestUrlEntityId() {
        if let entityId = self.requestEntityId {
            self.requestUrl = self.requestUrl! + self.requestEntity.rawValue + entityId + "/"
        }
        else {
            self.requestUrl = self.requestUrl! + self.requestEntity.rawValue
        }
    }
    
    private func appendRequestUrlEntity(entity: String?) {
        if let entity = entity {
            self.requestUrl = self.requestUrl! + entity + "/"
        }
        else {
            self.requestUrl = self.requestUrl!
        }
    }
    
    private func appendPushUrlEntityId() {
        if let entityId = self.requestEntityId {
            self.pushUrl = self.pushUrl! + self.requestEntity.rawValue + entityId + "/"
        }
        else {
            self.pushUrl = self.pushUrl! + self.requestEntity.rawValue
        }
    }
    
    open func apps(_ appId: String?) -> Self {
        self.requestEntity = .apps
        self.requestEntityId = appId
        self.appendRequestUrlEntityId()
        
        return self
    }
    
    open func secret() -> Self {
        self.requestEntity = .secret
        self.requestUrl = self.requestUrl! + self.requestEntity.rawValue

        return self
    }
    
    open func groups(_ groupId: String?) -> Self {
        self.requestEntity = .groups
        self.requestEntityId = groupId
        self.appendRequestUrlEntityId()

        return self
    }
    
    open func users(_ userId: String?) -> Self {
        self.requestEntity = .users
        self.requestEntityId = userId
        self.appendRequestUrlEntityId()
        self.appendPushUrlEntityId()
        
        return self
    }
    
    open func me() -> Self {
        self.requestEntity = .me
        self.requestUrl = self.requestUrl! + self.requestEntity.rawValue
        
        return self
    }
    
    open func history() -> Self {
        self.requestEntity = .history
        self.requestUrl = self.requestUrl! + self.requestEntity.rawValue
        
        return self
    }
    
    open func states(time: Date? = nil) -> Self {
        self.requestEntity = .states
        
        var suffix = ""
        
        if let time = time {
            suffix = self.sinceBeforeFormatter.string(from: time)
        }
        
        self.requestUrl = self.requestUrl! + self.requestEntity.rawValue + suffix
        
        return self
    }
    
    open func locations() -> Self {
        self.requestEntity = .locations
        self.requestUrl = self.requestUrl! + self.requestEntity.rawValue

        return self
    }
    
    open func image() -> Self {
        self.requestEntity = .image
        self.requestUrl = self.requestUrl! + self.requestEntity.rawValue

        return self
    }
    
    open func mojios(_ mojioId: String?) -> Self {
        self.requestEntity = .mojios
        self.requestEntityId = mojioId
        self.appendRequestUrlEntityId()
        self.appendPushUrlEntityId()

        return self
    }
    
    open func phonenumbers (_ phonenumber: String?, sendVerification: Bool?) -> Self {
        self.requestEntity = .phoneNumbers
        
        var phone: String? = phonenumber
        
        if phone != nil && sendVerification == true {
            phone = phone! + "?sendVerification=true"
        }
        
        self.requestEntityId = phone
        self.appendRequestUrlEntityId()

        return self
    }
    
    open func emails (_ email: String?) -> Self {
        self.requestEntity = .emails
        self.requestEntityId = email
        self.appendRequestUrlEntityId()
        
        return self
    }
    
    open func permission() -> Self {
        self.requestEntity = .permission
        self.requestUrl = self.requestUrl! + self.requestEntity.rawValue

        return self
    }
    
    open func permissions() -> Self {
        self.requestEntity = .permissions
        self.requestUrl = self.requestUrl! + self.requestEntity.rawValue

        return self
    }
    
    open func tags(_ tagId: String) -> Self {
        self.requestEntity = .tags
        self.requestUrl = self.requestUrl! + self.requestEntity.rawValue + tagId + "/"

        return self
    }
    
    open func trips(_ tripId: String?) -> Self {
        self.requestEntity = .trips
        self.requestEntityId = tripId
        self.appendRequestUrlEntityId()
        self.appendPushUrlEntityId()

        return self
    }
    
    open func vehicles(_ vehicleId: String?) -> Self {
        self.requestEntity = .vehicles
        self.requestEntityId = vehicleId
        self.appendRequestUrlEntityId()
        self.appendPushUrlEntityId()

        return self
    }
    
    public func vehicles(_ vehicleId: String, mergeVehicleId: String) -> Self {
        self.requestEntity = .vehicles
        self.requestEntityId = vehicleId
        self.requestParams["actual"] = mergeVehicleId as AnyObject?
        self.requestUrl = self.requestUrl! + self.requestEntity.rawValue + vehicleId + "/"
        self.pushUrl = self.pushUrl! + self.requestEntity.rawValue + vehicleId + "/"
        
        return self
    }

    open func notificationSettings() -> Self {
        self.requestEntity = .notificationSettings
        self.requestUrl = self.requestUrl! + self.requestEntity.rawValue
        return self
    }
    
    open func address() -> Self {
        self.requestEntity = .address
        self.requestUrl = self.requestUrl! + self.requestEntity.rawValue

        return self
    }
    
    open func vin() -> Self {
        self.requestEntity = .vin
        self.requestUrl = self.requestUrl! + self.requestEntity.rawValue

        return self
    }
    
    open func serviceSchedule() -> Self {
        self.requestEntity = .serviceSchedule
        self.requestUrl = self.requestUrl! + self.requestEntity.rawValue

        return self
    }
    
    open func next() -> Self {
        self.requestEntity = .next
        self.requestUrl = self.requestUrl! + self.requestEntity.rawValue

        return self
    }
    
    open func storage(_ key: String) -> Self {

        if let requestEntityId = self.requestEntityId {
            self.requestUrl = self.requestV1Url! + String.init(format: RestClientEndpoint.storage.rawValue, self.requestEntity.rawValue, requestEntityId, key)
        }

        return self
    }
    
    open func activities() -> Self {
        self.requestEntity = .activities
        self.requestUrl = self.requestUrl! + self.requestEntity.rawValue
        self.pushUrl = self.pushUrl! + self.requestEntity.rawValue + "/"
        return self
    }
    
    open func wifiRadio() -> Self {
        self.requestEntity = .wifiRadio
        self.requestUrl = self.requestUrl! + self.requestEntity.rawValue
        
        return self
    }
    
    open func transactions(_ transactionId: String?) -> Self {
        self.requestEntity = .transactions
        self.requestEntityId = transactionId
        self.appendRequestUrlEntityId()
        self.appendPushUrlEntityId()
        
        return self
    }
    
    open func geofences(_ geofenceId: String?) -> Self {
        self.requestEntity = .geofences
        self.requestEntityId = geofenceId
        self.appendRequestUrlEntityId()
        self.appendPushUrlEntityId()
        
        return self
    }
    
    open func aggregates(ofType type: String?) -> Self {
        
        self.requestEntity = .aggregates
        self.appendRequestUrlEntity(entity: type)
        
        return self
    }
    
    open func statistics() -> Self {
        self.requestEntity = .statistics
        self.requestUrl = self.requestUrl! + self.requestEntity.rawValue
        
        return self
    }

    open func diagnosticCodes(_ code: String?) -> Self {
        
        self.requestEntity = .diagnosticCodes
        self.appendRequestUrlEntity(entity: code)
        
        return self
    }
    
    public func polyline() -> Self {
        self.requestEntity = .polyline
        self.requestUrl = self.requestUrl! + self.requestEntity.rawValue
        
        return self
    }

    open func query(top: String? = nil, skip: String? = nil, filter: String? = nil, select: String? = nil, orderby: String? = nil, count: String? = nil, since: Date? = nil, before: Date? = nil, fields: [String]? = nil) -> Self {
        
        var requestParams: [String:AnyObject] = [:]
        
        if let top = top {
            requestParams["top"] = top as AnyObject?
        }

        if let skip = skip {
            requestParams["skip"] = skip as AnyObject?
        }

        if let filter = filter {
            requestParams["filter"] = filter as AnyObject?
        }

        if let select = select {
            requestParams["select"] = select as AnyObject?
        }

        if let orderby = orderby {
            requestParams["orderby"] = orderby as AnyObject?
        }
        
        if let count = count {
            requestParams["includeCount"] = count as AnyObject?
        }
        
        if let date = since {
            requestParams["since"] = self.sinceBeforeFormatter.string(from: date) as AnyObject?
        }

        if let date = before {
            requestParams["before"] = self.sinceBeforeFormatter.string(from: date) as AnyObject?
        }
        
        if let fields = fields , fields.count > 0 {
            requestParams["fields"] = fields.joined(separator: ",") as AnyObject?
        }
        
        
        self.requestParams.update(requestParams)
        return self
    }
    
    public func dispatch(queue: DispatchQueue) {
        self.dispatchQueue = queue
    }
    
    /*
     Don't need this helper function given default values in the other query function
     public func query(top: String?, skip: String?, filter: String?, select: String?, orderby: String?) -> Self {
        return self.query(top, skip: skip, filter: filter, select: select, orderby: orderby, since: nil, before: nil, fields: nil)
    }*/
    
    open func run(completion: @escaping (_ response: Any) -> Void, failure: @escaping (_ error: Any?) -> Void) {
        
        let request = Alamofire.request(self.requestUrl!, method: self.requestMethod, parameters: self.requestParams, encoding: URLEncoding(destination: .methodDependent), headers: self.defaultHeaders).responseJSON { response in
            self.handleResponse(response, completion: completion, failure: failure)
        }
        
        #if DEBUG
            print(request.debugDescription)
        #endif
    }
    
    fileprivate class CustomStringEncoding: ParameterEncoding {
        
        private let customString: String
        
        init(customString: String) {
            self.customString = customString
        }
        
        func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
            var urlRequest = urlRequest.urlRequest
            let quoteEscaped = self.customString.replacingOccurrences(of: "\\\"", with: "\\ \\ \"")
            let quotedString = String.init(format: "\"%@\"", quoteEscaped)
            urlRequest?.httpBody = quotedString.data(using: .utf8, allowLossyConversion: false)
            
            return urlRequest!
        }
    }
    
    fileprivate var defaultHeaders: [String: String] {
        var headers = ClientHeaders.defaultRequestHeaders
        
        headers.update(["Content-Type": "application/json", "Accept": "application/json"])
        
        // Before every request, make sure access token exists
        if let accessToken: String = self.accessToken() {
            headers["Authorization"] = "Bearer " + accessToken
        }
        
        return headers
    }
    
    open func runStringBody(string: String, completion: @escaping (_ response: Any) -> Void, failure: @escaping (_ error: Any?) -> Void) {
        
        let request = Alamofire.request(self.requestUrl!, method: self.requestMethod, parameters: [:], encoding: CustomStringEncoding(customString: string), headers: self.defaultHeaders).responseJSON { response in
            self.handleResponse(response, completion: completion, failure: failure)
        }
        
        #if DEBUG
            print(request.debugDescription)
        #endif
    }
    
    open func runEncodeJSON(jsonObject: AnyObject, completion: @escaping (_ response: Any) -> Void, failure: @escaping (_ error: Any?) -> Void) {
        
        let request = Alamofire.request(self.requestUrl!, method: self.requestMethod, parameters: [:], encoding: JSONEncoding.default, headers: self.defaultHeaders).responseJSON { response in
            self.handleResponse(response, completion: completion, failure: failure)
        }

        #if DEBUG
            print(request.debugDescription)
        #endif
    }
    
    open func runEncodeUrl(_ parameters: [String:AnyObject], completion: @escaping (_ response: Any) -> Void, failure: @escaping (_ error: Any?) -> Void) {
        
        // Before every request, make sure access token exists
        var headers: [String:String] = [:]
        
        if let accessToken: String = self.accessToken() {
            headers["Authorization"] = "Bearer " + accessToken
        }
        
        let request = Alamofire.request(self.requestUrl!, method: self.requestMethod, parameters: parameters, encoding: URLEncoding(destination: .methodDependent), headers: headers).responseJSON { response in
            self.handleResponse(response, completion: completion, failure: failure)
        }
        
        #if DEBUG
            debugPrint(request)
        #endif
    }
    
    func handleResponse(_ response: DataResponse<Any>, completion: @escaping (_ response :Any) -> Void, failure: @escaping (_ error: Any?) -> Void){
        if response.response?.statusCode == 200 || response.response?.statusCode == 201 {
            if let responseDict = response.result.value as? [String: Any] {
                if let dataArray = responseDict["Data"] as? [Any] {
                    let array: NSMutableArray = []
                    for  obj in dataArray {
                        if
                            let dict = obj as? [String: Any],
                            let model = self.parseDict(dict) {
                            
                            array.add(model)
                        }
                    }
                    var comp: Any = array
                    if let _ = requestParams["includeCount"] {
                        if let count = responseDict["TotalCount"] as? Int {
                            comp = Result(TotalCount: count, Data: array)
                        }
                    }
                    
                    completion(comp)

                    if (self.doNext) {
                        if let links = responseDict["Links"] as? [String: Any] {
                            if let next = links["Next"] as? String {
                                // Server sends the same nextUrl sometimes when you've reached the end
                                if let decoded = next.removingPercentEncoding {
                                    if (decoded != self.nextUrl) {
                                        self.nextUrl = decoded
                                        self.requestUrl = decoded
                                        self.requestParams = [:]
                                        self.run(completion: completion, failure:  failure)
                                        return
                                    }
                                }
                            }
                        }
                        completion(NextDone())
                    }
                }
                else {
                    if let obj = self.parseDict(responseDict) {
                        completion (obj)
                    }
                    else {
                        if let message: String = responseDict["Message"] as? String {
                            completion (message)
                        }
                        else {
                            completion ("")
                        }
                    }
                    
                }
            } else if let responseString = response.result.value as? String {
                completion(responseString);
            }
            else {
                completion(true)
            }
        }
        else {
            if let responseDict = response.result.value as? NSDictionary {
                failure (responseDict)
            }
            /*else if let responseError = response.result.error {
                failure (responseError.userInfo)
            }*/
            else {
                failure("Could not complete request")
            }
        }
    }
    
    open func parseDict(_ dict: [String: Any]) -> Any? {
        switch self.requestEntity {
            
        case .apps:
            let model = Mapper<App>().map(JSON: dict)
            return model!
            
        case .secret:
            return nil
            
        case .groups:
            let model = Mapper<Group>().map(JSON: dict)
            return model!
            
        case .users:
            let model = Mapper<User>().map(JSON: dict)
            return model!
            
        case .me:
            let model = Mapper<User>().map(JSON: dict)
            return model!
            
        case .history:
            return nil
            
        case .states:
            let model = Mapper<VehicleMeasures>().map(JSON: dict)
            return model!
            
        case .locations:
            let model = Mapper<Location>().map(JSON: dict)
            return model!

        case .image:
            let model = Mapper<Image>().map(JSON: dict)
            return model!

        case .mojios:
            let model = Mapper<Mojio>().map(JSON: dict)
            return model!
            
        case .trips:
            let model = Mapper<Trip>().map(JSON: dict)
            return model!

        case .vehicles:
            let model = Mapper<Vehicle>().map(JSON: dict)
            return model!
            
        case .address:
            let model = Mapper<Address>().map(JSON: dict)
            return model!
            
        case .vin:
            let model = Mapper<Vin>().map(JSON: dict)
            return model!
            
        case .serviceSchedule:
            let model = Mapper<ServiceSchedule>().map(JSON: dict)
            return model!
            
        case .next:
            let model = Mapper<NextServiceSchedule>().map(JSON: dict)
            return model!

        case .activities:
            let model = Mapper<RootActivity>().map(JSON: dict)
            return model!
            
        case .notificationSettings:
            let model = Mapper<NotificationsSettings>().map(JSON: dict)
            return model!
            
        case .wifiRadio:
            // Returns Transaction Id
            return dict["TransactionId"]
            
        case .transactions:
            // Returns Transaction State
            return dict["State"]
            
        case .geofences:
            let model = Mapper<Geofence>().map(JSON: dict)
            return model!

        case .aggregates:
            let model = Mapper<AggregationData>().map(JSON: dict)
            return model!

        case .statistics:
            let model = Mapper<VehicleStatistics>().map(JSON: dict)
            return model!
            
        case .polyline:
            let model = Mapper<TripPolyline>().map(JSON: dict)
            return model!
            
        default:
                return nil
        }
    }
    
    func accessToken() -> String? {
        return KeychainManager().getAuthToken().accessToken
    }    
}

public extension Dictionary {
    public mutating func update(_ updateDict: Dictionary) {
        for (key, value) in updateDict {
            self.updateValue(value, forKey:key)
        }
    }
}
