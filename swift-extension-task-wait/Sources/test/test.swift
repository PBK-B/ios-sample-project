import Foundation
// The Swift Programming Language
// https://docs.swift.org/swift-book


// 自定义超时错误类型
enum TaskWaitTimeoutError: Error {
    case timeout
}

@available(macOS 10.15, *)
extension Task {

    func wait(timeout: TimeInterval = -1) throws -> Success {
        var result: Result<Success, Error>?
        let semaphore = DispatchSemaphore(value: 0)

        let setValue = { value in
            result = .success(value)
        }
        let setValueFailure = { err in
            result = .failure(err)
        }

        Task<Success, Error> {
            defer {
                semaphore.signal() // 发送信号
            }
            do {
                let taskResult = try await self.value // 等待任务完成
                setValue(taskResult)
            } catch {
                setValueFailure(error)
            }
            return try await self.result.get()
        }

        // 判断是否有配置超时时间
        if timeout != -1 {
            // 等待信号，最多等待 timeout 秒
            let timeoutResult = semaphore.wait(timeout: .now() + timeout)
            if timeoutResult == .timedOut {
                throw TaskWaitTimeoutError.timeout // 抛出超时异常
            }
        } else {
            semaphore.wait()
        }

        guard let result else {
            throw NSError(domain: "result is nil", code: -1)
        }

        return try result.get()
    }
}
