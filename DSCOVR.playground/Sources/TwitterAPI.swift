import Foundation

private let urlSession = NSURLSession.sharedSession()

private extension NSMutableURLRequest
{
    /// A convenience extension allowing subscript syntax to modify a request:
    ///
    ///     request[header: "Content-Type"] = "application/x-www-form-urlencoded;charset=UTF-8"
    ///
    subscript(header field: String) -> String? {
        get { return valueForHTTPHeaderField(field) }
        set { setValue(newValue, forHTTPHeaderField: field) }
    }
}


public enum HTTPMethod: String {
    case GET
    case POST
}


/// An API helper object capable of making [application-only](https://dev.twitter.com/oauth/application-only)
/// authenticated requests to Twitter APIs: <https://dev.twitter.com/rest/public>.
public final class TwitterAPI
{
    private enum Error: ErrorType {
        case InvalidEndpoint
        case InvalidCredentials
        case InvalidParams
    }
    
    private lazy var operationQueue: NSOperationQueue = {
        let q = NSOperationQueue()
        q.qualityOfService = .UserInitiated
        q.name = "TwitterAPI@\(unsafeAddressOf(self))"
        return q
    }()
    
    private var authenticateOperation: NSOperation!
    private var bearerToken: String?
    
    
    /// Creates an API object authenticated with the given credentials.
    /// Obtain your credentials from <https://apps.twitter.com/>.
    public init(consumerKey: String, consumerSecret: String) throws
    {
        guard let ck = consumerKey.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet()),
            let cs = consumerSecret.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet()),
            let credentials = (ck + ":" + cs).dataUsingEncoding(NSUTF8StringEncoding)?.base64EncodedStringWithOptions([]) else
        {
            throw Error.InvalidCredentials
        }
        
        final class ClientCredentials: JSON {
            var bearerToken: String? {
                if self["token_type"]?.asString == "bearer" {
                    return self["access_token"]?.asString
                }
                return nil
            }
        }
        
        authenticateOperation = try makeAPICall(
            .POST, "oauth2/token",
            params: ["grant_type": "client_credentials"],
            headers: ["Authorization": "Basic " + credentials],
            needsAuthentication: false)
        { (result: ClientCredentials?) in
            self.bearerToken = result?.bearerToken
        }
    }
    
    /// Makes a call to a Twitter API, returning a result via `callback`.
    /// The response is assumed to be in JSON format, and is automatically parsed using `init(json:)`
    /// implementation provided the `ResultType`.
    /// - Parameter needsAuthentication: If true, the request will not execute until the authentication
    ///   initiated by `init(consumerKey:consumerSecret:)` has completed.
    /// - Returns: An NSOperation which has already been added to an internal queue for execution.
    ///   The caller may use it as a dependency for other operations if desired.
    ///
    /// Example usage:
    ///
    ///     twitter.makeAPICall([...]) { (result: MyJSONCreatableValue?) in
    ///         // use the result
    ///     }
    public func makeAPICall<ResultType: JSONCreatable>(
        method: HTTPMethod,
        _ endpoint: String,
        params: [String: String]? = nil,
        headers: [String: String] = [:],
        needsAuthentication: Bool = true,
        callback: ResultType? -> Void) throws -> NSOperation
    {
        let request = try buildRequest(method: method, endpoint: endpoint, params: params, headers: headers)
        
        let op = AsyncOperation { finishOperation in
            // Only try to grab the bearer token once we’ve started executing (meaning `authenticateOperation` has finished).
            if needsAuthentication {
                guard let token = self.bearerToken else {
                    print("Unable to authenticate; aborting request to \(endpoint). Did you forget to paste in your own consumer key and secret?")
                    finishOperation()
                    return
                }
                request[header: "Authorization"] = "Bearer " + token
            }
            
            urlSession.dataTaskWithRequest(request) { data, response, error in
                defer {
                    finishOperation()
                }
                
                guard let data = data else {
                    print("URL request for \(request.URL) failed: \(error)")
                    callback(nil)
                    return
                }
                
                do {
                    // Convert the data to JSON, and then to the requested ResultType.
                    let json = try JSON(data: data)
                    let result = try ResultType(json: json)
                    callback(result)
                }
                catch {
                    print("JSON was not convertible to \(ResultType.self) for \(request.URL): \(error)")
                    callback(nil)
                }
            }.resume()
        }
        
        if needsAuthentication {
            // Don’t run any requests which require authentication until we’ve been authenticated.
            op.addDependency(authenticateOperation)
        }
        
        operationQueue.addOperation(op)
        return op
    }
    
    
    /// Construct a NSURLRequest from the given API method, parameters, etc.
    ///
    /// (A `NSMutableURLRequest` is returned, so that the request can be further modified if desired.)
    private func buildRequest(method method: HTTPMethod,
                              endpoint: String,
                              params: [String: String]?,
                              headers: [String: String]) throws -> NSMutableURLRequest
    {
        let request = NSMutableURLRequest()
        request.HTTPMethod = method.rawValue
        
        for (k, v) in headers {
            request[header: k] = v
        }
        
        let components = NSURLComponents()
        components.scheme = "https"
        components.host = "api.twitter.com"
        components.path = "/" + endpoint
        components.queryItems = params?.map{ k, v in NSURLQueryItem(name: k, value: v) }
        
        switch method {
        case .GET:
            // Use `params` as GET params in the URL.
            break
            
        case .POST:
            // Convert `params` to a form-encoded POST body.
            guard let postBody = components.percentEncodedQuery?.dataUsingEncoding(NSUTF8StringEncoding) else {
                throw Error.InvalidParams
            }
            components.queryItems = nil
            request.HTTPBody = postBody
            request[header: "Content-Type"] = "application/x-www-form-urlencoded;charset=UTF-8"
        }
        
        guard let url = components.URL else {
            throw Error.InvalidEndpoint
        }
        
        request.URL = url
        return request
    }
}

