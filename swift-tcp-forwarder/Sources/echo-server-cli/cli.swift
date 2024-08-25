// The Swift Programming Language
// https://docs.swift.org/swift-book

import ArgumentParser
import CocoaAsyncSocket
import Foundation
import Network

public class TCPEchoServer: NSObject, GCDAsyncSocketDelegate {
    let ECHO_MSG = 1
    var localListenSocket: GCDAsyncSocket!
    var clientSocket: GCDAsyncSocket!

    // 获取本地监听地址
    public var localAddress: String {
        "\(localListenSocket.localHost ?? "127.0.0.1"):\(localListenSocket.localPort)"
    }

    override public init() {
        super.init()
        localListenSocket = GCDAsyncSocket(delegate: self, delegateQueue: .main)
    }

    deinit {
        localListenSocket.disconnect() // 关闭本地端口监听
    }

    public func start(to localHost: String, localPort: UInt16) throws {
        if localHost == "0.0.0.0" {
            try localListenSocket.accept(onPort: localPort)
        } else {
            try localListenSocket.accept(onInterface: localHost, port: localPort)
        }
        print("start \(localHost)")
    }

    public func socket(_: GCDAsyncSocket, didRead data: Data, withTag _: Int) {
        print("socket didRead \(String(data: data, encoding: .utf8) ?? "nil")")
        clientSocket.write("[echo] ".data(using: .ascii), withTimeout: -1, tag: 0)
        clientSocket.write(data, withTimeout: -1, tag: ECHO_MSG)
    }

    public func socket(_: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        // print("socket didWriteDataWithTag \(tag)")
        if tag == ECHO_MSG {
            clientSocket.readData(withTimeout: -1, tag: tag)
        }
    }

    public func socket(_: GCDAsyncSocket, didAcceptNewSocket: GCDAsyncSocket) {
        didAcceptNewSocket.setDelegate(self, delegateQueue: .global())
        clientSocket = didAcceptNewSocket
        clientSocket.readData(withTimeout: -1, tag: 0)
        print("socket didAcceptNewSocket")
    }
}

@main
struct cli: ParsableCommand {
    @Option var input: String = "Hello bin, Welcome to use TCPForwarder"
    @Option var local: String
    @Option var remote: String

    mutating func run() throws {
        // 判断传入地址是否正确
        let _localAddr = try IPv4SocketAddress(local)

        let tcpProxy = TCPEchoServer()

        try tcpProxy.start(to: _localAddr.host, localPort: _localAddr.port)

        // IPv4Address.any.debugDescription
        print("[CLI] \(input), server listen in \(_localAddr.host):\(_localAddr.port)")
        RunLoop.main.run()
    }
}

struct IPv4SocketAddress {
    var host: String
    var port: UInt16

    init(_ address: String) throws {
        let _subs = address.components(separatedBy: ":")
        if _subs.count < 2 {
            throw NSError(domain: "\(address) address is wrong", code: -1)
        }
        guard let _port = UInt16(argument: _subs[1]), _port > 0, _port < 65535 else {
            throw NSError(domain: "\(_subs[1]) port is wrong", code: -1)
        }
        host = _subs[0]
        port = _port
    }
}
