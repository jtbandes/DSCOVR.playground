import Foundation

/// A convenience wrapper for a JSON object representing a tweet.
/// This class can be used as the response type for API calls that return tweets, such as
/// [user_timeline.json](https://dev.twitter.com/rest/reference/get/statuses/user_timeline).
public final class Tweet: JSON
{
    /// - Returns: The tweet text with links removed.
    public var caption: String {
        guard let originalText = self["text"]?.asString else { return "" }
        
        let range = NSRange(location: 0, length: (originalText as NSString).length)
        let result = try? NSDataDetector(types: NSTextCheckingType.Link.rawValue)
            .stringByReplacingMatchesInString(originalText, options: [], range: range, withTemplate: "")
        
        let usernamePrefix = self["user", "screen_name"]?.asString.map{ "@\($0) " } ?? ""
        return usernamePrefix + (result ?? originalText)
    }
    
    /// - Returns: The URL for the first photo included in the tweet, if any.
    public var photoURL: NSURL? {
        return self["entities", "media", 0, "media_url_https"]?.asString.flatMap {
            NSURL(string: $0 + ":large")
        }
    }
}
