import QuartzCore

/// The purpose of this class is to "debounce" a 'call' that happens as a result of a rapid callback
/// But needs to be rate limited for performance reasons.
public class Debouncer {

    /// The minimum time interval before calls will execute again
    private let bounceTime: CFTimeInterval

    /// The recorded time of the last executed call
    private var timeOfLastCall: CFTimeInterval?

    public init(bounceTime: CFTimeInterval) {
        self.bounceTime = bounceTime
    }

    /// the provided closure will be executed on the current queue if the last executed call was longer ago
    /// than the provided bounce time.
    public func call(_ closure: () -> Void) {
        let currentTime = CACurrentMediaTime()
        if let timeOfLastCall = timeOfLastCall {
            if currentTime - timeOfLastCall > bounceTime {
                self.timeOfLastCall = currentTime
                closure()
            }
        } else {
            self.timeOfLastCall = currentTime
            closure()
        }
    }
}
