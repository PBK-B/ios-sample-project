@testable import test
import XCTest

final class testTests: XCTestCase {
    struct TestError: Error {}

    func testWaitSuccess() {
        // 创建一个异步任务，模拟成功的情况
        let asyncTask = Task {
            await Task.sleep(3 * 1_000_000_000) // 模拟异步操作，等待 3 秒
            return "Task completed"
        }

        do {
            // 调用 wait 方法等待任务完成
            let result = try asyncTask.wait()

            XCTAssertEqual(result, "Task completed", "Result should be 'Task completed'")

            // 测试成功时输出信息到控制台
            let activity = XCTContext.runActivity(named: "Test successful") { _ in
                print("[TestWaitSuccess] result: \(result)")
            }

            XCTAssertNotNil(activity, "Activity should not be nil")

        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testWaitFailure() {
        // 创建一个异步任务，模拟失败的情况
        let asyncTask = Task {
            await Task.sleep(3 * 1_000_000_000) // 模拟异步操作，等待 3 秒
            throw TestError()
        }

        do {
            // 调用 wait 方法等待任务完成
            _ = try asyncTask.wait(timeout: 2)
            XCTFail("Expected error but got success")
        } catch TaskWaitTimeoutError.timeout {
            // 预期超时异常
            XCTAssert(true, "Timeout error occurred")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testWaitNotThrows() {
        // 创建一个异步任务，模拟失败的情况
        let asyncTask = Task {
            await Task.sleep(3 * 1_000_000_000) // 模拟异步操作，等待 3 秒
            throw TestError()
        }

        // 调用 wait 方法等待任务完成
        if let _ = asyncTask.waitNotThrows(timeout: 2) {
            XCTFail("Expected error but got success")
        } else {
            // 预期超时异常
            XCTAssert(true, "Timeout error occurred")
        }
    }
}
