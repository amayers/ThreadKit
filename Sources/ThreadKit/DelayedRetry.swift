import Foundation

/// A utility that performs automatic retries of a task that can fail with a exponential backoff delay between each retry attempt
public enum DelayedRetry {
    private enum Constants {
        static let retryDelayForOneRetryRemaining: TimeInterval = 4.0
    }

    /// What attempt number is this? Useful so if == 1 you know this is the first attempt and not actually a retry
    public typealias AttemptNumber = Int
    public typealias TaskResult = (_ success: Bool) -> Void
    public typealias Task = (AttemptNumber, @escaping TaskResult) -> Void
    public typealias RetryAttemptsFailed = (() -> Void)

    /// Overload for testing where we can setup a faster delay so tests don't take 5+ seconds for this one test.
    static func performTask(on queue: DispatchQueue, attemptNumber: AttemptNumber, numberOfRetries: Int, delayCalculator: @escaping (Int) -> TimeInterval,
                            finishedAllRetryAttempts: RetryAttemptsFailed?, task: @escaping Task) {
        queue.async {
            task(attemptNumber, { (success) in
                guard !success else {
                    return
                }
                if numberOfRetries > 0 {
                    let delay = delayCalculator(numberOfRetries)
                    queue.asyncAfter(deadline: .now() + delay, execute: {
                        performTask(on: queue, attemptNumber: attemptNumber + 1, numberOfRetries: numberOfRetries - 1, delayCalculator: delayCalculator,
                                    finishedAllRetryAttempts: finishedAllRetryAttempts, task: task)
                    })
                } else if let finishedAllRetryAttempts = finishedAllRetryAttempts {
                    queue.async(execute: finishedAllRetryAttempts)
                }
            })
        }
    }

    /// Perform a task on a queue. If that task fails, this will retry running that task with an exponential growing delay before each retry
    /// attempt.
    ///
    /// - Parameters:
    ///   - queue: The queue that the `task` will be run on asynchronously
    ///   - numberOfRetries: How many times will this `task` be rerun if you say it has failed
    ///   - finishedAllRetryAttempts: Will be called on the `queue` only if we have retried the task `numberOfRetries` and all attempts have failed.
    ///   - task: The task that is to be performed. Once you are finished your work inside the task, call the `TaskResult` parameter with a `true` if it
    ///           was completed successfully (no retry needed), or `false` if the task should be retried. It is up to the caller to ensure that running the
    ///           `task` multiple times won't cause issues. This closure is not retained beyond the minimum required to run/retry the task.
    public static func performTask(on queue: DispatchQueue, numberOfRetries: Int, finishedAllRetryAttempts: RetryAttemptsFailed?, task: @escaping Task) {
        performTask(on: queue, attemptNumber: 1, numberOfRetries: numberOfRetries, delayCalculator: delay(forNumberOfRemainingRetries:),
                    finishedAllRetryAttempts: finishedAllRetryAttempts, task: task)
    }

    /// Compute the delay for the next retry based on the number of retries remaining.
    ///
    /// - Parameter retriesRemaining: The number of retires remaining before we stop retrying
    /// - Returns: How long to delay before starting the next retry. The delay is the longest if this is the last retry attempt, and is cut in half for each
    ///            additional retry remaining. So 1 retry remain = 4 second delay, 2 retry remain = 2 second delay, 3 retry = 1 second delay and so on.
    static func delay(forNumberOfRemainingRetries retriesRemaining: Int) -> TimeInterval {
        if retriesRemaining <= 1 {
            return Constants.retryDelayForOneRetryRemaining
        } else {
            return delay(forNumberOfRemainingRetries: retriesRemaining - 1) / 2
        }
    }
}
