import Foundation
@testable import swift_tcp_forwarder
import TCPForwarder
import XCTest

final class swift_tcp_forwarderTests: XCTestCase {
    var asyncExpectation: XCTestExpectation!

    func testExample() throws {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
        // let tcp = TCPForwarder()
        print("server run…")
        do {
            let tcp = TCPForwarder1()
            try tcp.start(to: "127.0.0.1", localPort: 2230)
            print("server \(tcp.localAddress)")
        } catch {
            print("error \(error)")
        }
    }

    func testExampleLoop() throws {
        asyncExpectation = expectation(description: "longRunningFunction")

        waitForExpectations(timeout: 25.0) { error in
            if let error = error {
                print("Error \(error)")
            }
        }
    }
}
