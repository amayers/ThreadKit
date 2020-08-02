import Foundation

/// A thin wrapper around a DispatchQueue that provides easy methods to do a sync/async task on a queue,
/// without having to always queue the work on the end of the queue
public final class Queue {
    /// The underlying DispatchQueue. Feel free to use it directly if you need.
    public let queue: DispatchQueue

    private let value = UUID()
    private let key = DispatchSpecificKey<UUID>()

    public init(label: String, qos: DispatchQoS = .userInteractive, attributes: DispatchQueue.Attributes = [],
                autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency = .workItem, target: DispatchQueue? = .global(qos: .default)) {
        queue = DispatchQueue(label: label, qos: qos, attributes: attributes, autoreleaseFrequency: autoreleaseFrequency, target: target)
        queue.setSpecific(key: key, value: value)
    }

    /// If you call this while already executing on the internal queue, then the closure is directly executed, with no call to
    /// `queue.sync()` added. This can be helpful in preventing situations where you need to ensure work is done on the queue,
    /// but you might already be on the queue, and don't want a deadlock.
    ///
    /// - Parameter closure: The work to perform
    public func syncOnQueueIfNeeded(_ closure: () -> Void) {
        if DispatchQueue.getSpecific(key: key) == value {
            dispatchPrecondition(condition: .onQueue(queue))
            closure()
        } else {
            queue.sync(execute: closure)
        }
    }

    /// If you call this while already executing on the internal queue, then the closure is directly executed, with no call to
    /// `queue.sync()` added. This can be helpful in preventing situations where you need to ensure work is done on the queue,
    /// but you might already be on the queue, and don't want a deadlock.
    ///
    /// - Parameter closure: The work to perform
    public func asyncOnQueueIfNeeded(_ closure: @escaping () -> Void) {
        if DispatchQueue.getSpecific(key: key) == value {
            dispatchPrecondition(condition: .onQueue(queue))
            closure()
        } else {
            queue.async(execute: closure)
        }
    }
}
