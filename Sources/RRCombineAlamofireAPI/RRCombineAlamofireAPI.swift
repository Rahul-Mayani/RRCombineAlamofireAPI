import Foundation
import Combine
import Alamofire

final public class RRCombineAlamofireAPI: Publisher {
    
    /// `Singleton` variable of API class
    public static let shared = RRCombineAlamofireAPI()
    
    /// It's private for subclassing
    private init() {}
    
    // MARK: Types
    
    /// The response of data type.
    public typealias Output = Data
    public typealias Failure = Error
    
    // MARK: - Properties
    
    /// `Session` creates and manages Alamofire's `Request` types during their lifetimes. It also provides common
    /// functionality for all `Request`s, including queuing, interception, trust management, redirect handling, and response
    /// cache handling.
    private(set) var sessionManager: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 1200.0
        return Alamofire.Session(configuration: configuration)
    }()
    
    /// `HTTPHeaders` value to be added to the `URLRequest`. Set `["Content-Type": "application/json"]` by default..
    private(set) var headers: HTTPHeaders = ["Content-Type": "application/json"]
        
    /// `URLConvertible` value to be used as the `URLRequest`'s `URL`.
    private(set) var url: String?
    
    /// `HTTPMethod` for the `URLRequest`. `.get` by default..
    private(set) var httpMethod: HTTPMethod = .get
    
    /// `Param` (a.k.a. `[String: Any]`) value to be encoded into the `URLRequest`. `nil` by default..
    private(set) var param: [String: Any]?
    
         
    // MARK: - Initializer
    
    /// Set param
    ///
    /// - Parameter sessionManager: `Session` creates and manages Alamofire's `Request` types during their lifetimes.
    /// - Returns: Self
    public func setSessionManager(_ sessionManager: Session) -> Self {
        self.sessionManager = sessionManager
        return self
    }
    
    /// Set param
    ///
    /// - Parameter headers: a dictionary of parameters to apply to a `HTTPHeaders`.
    /// - Returns: Self
    public func setHeaders(_ headers: [String: String]) -> Self {
        for param in headers {
            self.headers[param.key] = param.value
        }
        return self
    }
    
    /// Set url
    ///
    /// - Parameter apiUrl: URL to set for api request
    /// - Returns: Self
    public func setURL(_ url: String) -> Self {
        self.url = url
        return self
    }
    
    /// Set httpMethod
    ///
    /// - Parameter httpMethod: to change as get, post, put, delete etc..
    /// - Returns: Self
    public func setHttpMethod(_ httpMethod: HTTPMethod) -> Self {
        self.httpMethod = httpMethod
        return self
    }
    
    /// Set param
    ///
    /// - Parameter param: a dictionary of parameters to apply to a `URLRequest`.
    /// - Returns: Self
    public func setParameter(_ param: [String:Any]) -> Self {
        self.param = param
        return self
    }
    
    
    /// The parameter encoding. `URLEncoding.default` by default.
    private func encoding(_ httpMethod: HTTPMethod) -> ParameterEncoding {
        var encoding : ParameterEncoding = JSONEncoding.default
        if httpMethod == .get {
            encoding = URLEncoding.default
        }
        return encoding
    }
    
    /// Subscriber for `observer` that can be used to cancel production of sequence elements and free resources.
    public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        
        let urlQuery = url!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        /// Creates a `DataRequest` from a `URLRequest`.
        /// Responsible for creating and managing `Request` objects, as well as their underlying `NSURLSession`.
        let request = sessionManager.request(urlQuery,
                                             method: httpMethod,
                                             parameters: param,
                                             encoding: self.encoding(httpMethod),
                                             headers: self.headers)
            /*.cURLDescription { description in
                debugPrint(" cURL Request ")
                debugPrint(description)
                debugPrint("")
            }*/
            
        subscriber.receive(subscription: Subscription(request: request, target: subscriber))
    }
}

extension RRCombineAlamofireAPI {
    // MARK: - Subscription -
    private final class Subscription<Target: Subscriber>: Combine.Subscription where Target.Input == Output, Target.Failure == Failure {
        private var target: Target?
        private let request: DataRequest
        
        init(request: DataRequest, target: Target) {
            self.request = request
            self.target = target
        }
        
        func request(_ demand: Subscribers.Demand) {
            assert(demand > 0)

            guard let target = target else { return }
            
            self.target = nil
            request.responseJSON { response in
                if response.response?.statusCode == RRHTTPStatusCode.unauthorized.rawValue {
                    target.receive(completion: .failure(RRError.unauthorized))
                    return
                }
                switch response.result {
                case .success :
                    _ = target.receive(response.data ?? Data())
                    target.receive(completion: .finished)
                case .failure(let error):
                    if error.isSessionTaskError {
                        target.receive(completion: .failure(RRError.noInternetConnection))
                    } else {
                        target.receive(completion: .failure(error))
                    }
                }
            }
            .resume()
        }
        
        func cancel() {
            request.cancel()
            target = nil
        }
    }
}

