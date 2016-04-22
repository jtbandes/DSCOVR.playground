import Foundation

/// An operation which fetches an image from a given URL.
public final class FetchImageOperation: AsyncOperation
{
    /// After the operation executes, this property will be set to the image that was fetched
    /// (or `nil` if an error occurred).
    public var image: NativeImage?
    
    public init(url: NSURL)
    {
        // Only set executionBlock after init, because it requires capturing `self`.
        super.init(executionBlock: nil)
        
        executionBlock = { [weak self] finishBlock in
            NSURLSession.sharedSession().dataTaskWithURL(url) { data, response, error in
                if let strongSelf = self {
                    strongSelf.image = data.flatMap{ NativeImage(data: $0) }
                }
                if let error = error {
                    print("error fetching \(url): \(error)")
                }
                finishBlock()
            }.resume()
        }
    }
}
