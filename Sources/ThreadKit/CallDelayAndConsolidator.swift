import Foundation

/// Delays calls a specified amount, and consolidates all calls that come in, during that delay. Only the last one will be fired.
public class CallDelayAndConsolidator {

    private let queue: DispatchQueue
    private var latestSetTime: CFTimeInterval?

    /// The queue that all calls will be made one
    public init(queue: DispatchQueue) {
        self.queue = queue
    }

    /// Queues up a call to be fired after some delay. If another call is submitted to this consolidator during that delay, the delay starts anew for that
    /// new call, and previous calls will be discarded.
    public func performCall(with delay: TimeInterval, call: @escaping () -> Void) {
        let setTime = CFAbsoluteTimeGetCurrent()
        latestSetTime = setTime
        queue.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self, let latestSetTime = self.latestSetTime, latestSetTime == setTime else {
                return
            }
            self.latestSetTime = nil
            call()
        }
    }
}
