import Foundation

/// Wraps a closure to be called, along with the queue on which to call it.
///
/// It is a common pattern that asynchronous methods take in a completion closure that is called when the work is done. However it is often not enforced
/// what queue that closure gets called on. You can add a `queue` parameter to such methods that is used just for calling the completion handler
/// and that is probably the most correct way. However that can have other issues. That queue property can shadow the type's private queue that you meant
/// to do all the work on, and so you block the passed in `queue` while doing that work, instead of just when calling the completion closure (had this happen).
/// You could also just always use some arbitrary queue to call the completion. But then you need to document which queue the closure is called on.
/// This documentation often becomes incorrect after changes down the road, and now the completion is called on a different queue then documented (had this).
/// This type enforces that the function's caller can choose which queue to use for the completion closure, it must be called on that closure, and no other
/// work can easily be performed on that queue.
public struct Completion<ClosureParam> {

    /// Create the completion handler. If you wish to release the `queue` and `closure` just release your reference to this Completion struct.
    ///
    /// - Parameters:
    ///   - queue: The queue to use when calling `closure`
    ///   - closure: The function to be called on `queue` at a later time.
    public init(queue: DispatchQueue, closure: @escaping (ClosureParam) -> Void) {
        self.queue = queue
        self.closure = closure
    }

    /// Call this when you want to have the completion closure called.
    ///
    /// - Parameter value: The value to pass to the completion closure.
    public func complete(value: ClosureParam) {
        self.queue.async {
            self.closure(value)
        }
    }

    // MARK: - Private

    private let queue: DispatchQueue
    private let closure: (ClosureParam) -> Void
}
