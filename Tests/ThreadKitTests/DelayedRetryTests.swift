@testable import ThreadKit
import XCTest

class DelayedRetryTests: XCTestCase {

    func testDelay() {
        XCTAssert(DelayedRetry.delay(forNumberOfRemainingRetries: 1) == 4)
        XCTAssert(DelayedRetry.delay(forNumberOfRemainingRetries: 2) == 2)
        XCTAssert(DelayedRetry.delay(forNumberOfRemainingRetries: 3) == 1)
        XCTAssert(DelayedRetry.delay(forNumberOfRemainingRetries: 4) == 0.5)
        XCTAssert(DelayedRetry.delay(forNumberOfRemainingRetries: 5) == 0.25)
        XCTAssert(DelayedRetry.delay(forNumberOfRemainingRetries: 6) == 0.125)
    }

    func testRetry() {
        var delayCalculatorRemaining = 0
        var taskRunCount = 0
        let numberOfRetries = 6
        var expectedAttemptNumber = 1
        let taskExpectation = expectation(description: "Task retry")

        DelayedRetry.performTask(on: .main, attemptNumber: 1, numberOfRetries: numberOfRetries, delayCalculator: { (_) in
            delayCalculatorRemaining += 1
            return 0
        }, finishedAllRetryAttempts: {
            // 3 retries + the first run
            XCTAssert(taskRunCount == numberOfRetries + 1)
            XCTAssert(delayCalculatorRemaining == numberOfRetries)
            taskExpectation.fulfill()
        }, task: { (attemptNumber, result) in
            XCTAssertEqual(expectedAttemptNumber, attemptNumber)
            expectedAttemptNumber += 1
            taskRunCount += 1
            result(false)
        })

        wait(for: [taskExpectation], timeout: 4)
    }

    func testNoRetry() {
        let taskExpectation = expectation(description: "Task retry")
        var delayCalculatorRemaining = 0
        var taskRunCount = 0
        let numberOfRetries = 6
        var expectedAttemptNumber = 1

        DelayedRetry.performTask(on: .main, attemptNumber: 1, numberOfRetries: numberOfRetries, delayCalculator: { (_) in
            delayCalculatorRemaining += 1
            return 0
        }, finishedAllRetryAttempts: {
            XCTFail("All retry attempts attempted when we shouldn't have retried even once")
            taskExpectation.fulfill()
        }, task: { (attemptNumber, result) in
            XCTAssertEqual(expectedAttemptNumber, attemptNumber)
            expectedAttemptNumber += 1
            taskRunCount += 1
            result(true)
            XCTAssert(taskRunCount == 1)
            XCTAssert(delayCalculatorRemaining == 0)
            taskExpectation.fulfill()
        })

        wait(for: [taskExpectation], timeout: 4)
    }
}
