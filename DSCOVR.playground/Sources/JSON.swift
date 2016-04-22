import Foundation

/// This protocol enables our APIs to produce any "kind" of JSON object by using generics.
/// Functions can be declared like `func makeAPIRequest<T: JSONCreatable>(...)` and simply use
/// `T(json: JSON(data: ...))` to produce the JSON-creatable type requested by the caller.
///
/// The easiest way to make a custom type JSONCreatable is by inheriting from the JSON class,
/// and defining convenience accessors which return optional values:
///
///     class MyType: JSON {
///         var myConvenienceVariable: String? {
///             return self["some", 0, "key", "path"]?.asString
///         }
///     }
public protocol JSONCreatable
{
    init(json: JSON) throws
}


extension Array: JSONCreatable
{
    /// Arrays of JSONCreatable elements are automatically creatable from JSON.
    ///
    /// (Attempting to construct from JSON an array whose Element type is non-JSONCreatable will throw an error.
    ///  In the future, Swift 3+ may bring improvements to generics which allow us to enforce this at compile-time.)
    public init(json: JSON) throws
    {
        guard let Witness = Element.self as? JSONCreatable.Type, let array = json.asArray else {
            throw JSON.Error.TypeMismatch
        }
        self = try array.map { try Witness.init(json: $0) as! Element }
    }
}


/// A class which stores a JSON object and provides convenient accessors for traversal and type conversion:
///
///     json.asString, json.asNumber, json.asBool, json.asArray
///     json["stuff"], json["stuff"][2], json["stuff", 2]
public class JSON: JSONCreatable
{
    private final var storage: AnyObject
    private init(storage: AnyObject) {
        self.storage = storage
    }
    
    public enum Error: ErrorType {
        case TypeMismatch
    }
    
    public enum SubscriptPathComponent: StringLiteralConvertible, IntegerLiteralConvertible {
        case ObjectKey(String)
        case ArrayIndex(Int)
        
        public init(integerLiteral value: Int) { self = .ArrayIndex(value) }
        public init(stringLiteral value: String) { self = .ObjectKey(value) }
        public init(extendedGraphemeClusterLiteral value: String) { self = .ObjectKey(value) }
        public init(unicodeScalarLiteral value: String) { self = .ObjectKey(value) }
    }
    
    public required init(json: JSON) throws {
        storage = json.storage
    }
    
    public required init(data: NSData) throws {
        storage = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
    }
    
    public final var asString: String? {
        return storage as? String
    }
    
    public final var asNumber: NSNumber? {
        return storage as? NSNumber
    }
    
    public final var asBool: NSNumber? {
        return storage as? Bool
    }
    
    public final var asArray: [JSON]? {
        return (storage as? [AnyObject])?.map { JSON(storage: $0) }
    }
    
    public final subscript(path: SubscriptPathComponent...) -> JSON? {
        return self[pathComponents: path]
    }
    
    public final subscript(component: SubscriptPathComponent) -> JSON? {
        return self[pathComponents: [component]]
    }
    
    private subscript(pathComponents path: [SubscriptPathComponent]) -> JSON?
    {
        // Traverse through the object according to the given subscript path.
        var storage = self.storage
        for component in path {
            switch component {
            case .ArrayIndex(let index):
                guard let array = storage as? [AnyObject] where index < array.count else { return nil }
                storage = array[index]
                
            case .ObjectKey(let key):
                guard let object = storage as? [String: AnyObject], let value = object[key] else { return nil }
                storage = value
            }
        }
        return JSON(storage: storage)
    }
}


extension JSON: CustomStringConvertible
{
    public var description: String {
        return storage.description ?? "JSON@\(unsafeAddressOf(self))"
    }
}

