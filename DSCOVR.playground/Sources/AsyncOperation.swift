import Foundation

/// An operation whose execution is asynchronous.
public class AsyncOperation: NSOperation
{
    public typealias FinishBlock = () -> Void
    
    /// The `executionBlock` will be called from the operation’s `start` method (which is
    /// automatically called by NSOperationQueue. The `FinishBlock` passed in can be called
    /// to complete the operation.
    /// - Important: If `executionBlock` captures `self` strongly, this is a retain cycle.
    /// If the operation never executes, this will result in a memory leak.
    public var executionBlock: (FinishBlock -> Void)?
    public init(executionBlock: (FinishBlock -> Void)?)
    {
        self.executionBlock = executionBlock
    }
    
    override public final func start()
    {
        guard let executionBlock = executionBlock else {
            assertionFailure("executionBlock must be set; start() should not be called more than once")
            return
        }
        self.executionBlock = nil
        
        executing = true
        executionBlock {
            self.executing = false
            self.finished = true
        }
    }
    
    private var _executing = false
    private var _finished = false
    
    public private(set) override var executing: Bool {
        get { return _executing }
        set {
            willChangeValueForKey("isExecuting")
            _executing = newValue
            didChangeValueForKey("isExecuting")
        }
    }
    
    public private(set) override var finished: Bool {
        get { return _finished }
        set {
            willChangeValueForKey("isFinished")
            _finished = newValue
            didChangeValueForKey("isFinished")
        }
    }
}
