//
//  TCPForwarder.swift
//  hclient3
//
//  Created by Bin on 2024/4/10.
//

import CocoaAsyncSocket
import Foundation

public struct TCPForwarderSocket {
    var remoteSocket: GCDAsyncSocket
    var clientSocket: GCDAsyncSocket

    init(client: GCDAsyncSocket, remote: GCDAsyncSocket) {
        clientSocket = client
        remoteSocket = remote
    }

    init(client: GCDAsyncSocket, remoteDelegate: GCDAsyncSocketDelegate) {
        let remote = GCDAsyncSocket(delegate: remoteDelegate, delegateQueue: .global())
        self.init(client: client, remote: remote)
    }

    // 获取客户端地址
    var clientAddress: String {
        "\(clientSocket.connectedHost ?? ""):\(clientSocket.connectedPort)"
    }

    // 断开链接
    func disconnect() {
        if remoteSocket.isConnected {
            remoteSocket.disconnect()
        }
        if clientSocket.isConnected {
            clientSocket.disconnect()
        }
    }
}

class TCPForwarder: NSObject, GCDAsyncSocketDelegate {
    var localListenSocket: GCDAsyncSocket!
    var sourceHost: String?, sourcePort: UInt16?
    var connectSockets: [TCPForwarderSocket] = []

    // 获取本地监听地址
    var localAddress: String {
        "\(localListenSocket.localHost ?? "127.0.0.1"):\(localListenSocket.localPort)"
    }

    override init() {
        super.init()

        localListenSocket = GCDAsyncSocket(delegate: self, delegateQueue: .global())
    }

    deinit {
        localListenSocket.disconnect() // 关闭本地端口监听

        for item in connectSockets {
            item.disconnect() // 将全部连接客户端断开连接
        }
        connectSockets.removeAll() // 移除全部连接
    }

    func start(from sourceHost: String, sourcePort: UInt16, to localHost: String, localPort: UInt16) throws {
        self.sourceHost = sourceHost
        self.sourcePort = sourcePort

        if localHost == "0.0.0.0" {
            try localListenSocket.accept(onPort: localPort)
        } else {
            try localListenSocket.accept(onInterface: localHost, port: localPort)
        }
    }

    func socket(_: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        // 连接远程TCP服务器
        var proxyItem: TCPForwarderSocket?
        proxyItem = connectSockets.filter { $0.clientSocket == newSocket }.first

        if proxyItem == nil {
            // 构建 ForwarderSocket
            let remoteSocket = GCDAsyncSocket(delegate: self, delegateQueue: .global())
            proxyItem = TCPForwarderSocket(client: newSocket, remote: remoteSocket)
            connectSockets.append(proxyItem!)
        }

        print("TCPForwarder didAcceptNewSocket \(proxyItem?.clientAddress ?? "nil")")

        do {
            guard let proxyItem else {
                return
            }

            if proxyItem.remoteSocket.isConnected {
                // 如果判断远程已经连接的话先断开连接
                proxyItem.remoteSocket.disconnect()
            }

            // 连接远程地址
            try proxyItem.remoteSocket.connect(toHost: sourceHost ?? "", onPort: sourcePort ?? 0)

            // 关联本地监听Socket和远程Socket
            proxyItem.clientSocket.readData(withTimeout: -1, tag: 0)
            proxyItem.remoteSocket.readData(withTimeout: -1, tag: 0)
            print("TCPForwarder remoteSocket Connecting to remote TCP server")
        } catch {
            // 连接远程失败后，需要移除连接列表
            if let proxyItem, let index = connectSockets.firstIndex(where: { $0.clientSocket == proxyItem.clientSocket }) {
                proxyItem.disconnect()
                if index >= 0 && connectSockets.count > index {
                    connectSockets.remove(at: index)
                }
            }
            print("TCPForwarder remoteSocket Error connecting to remote TCP server: \(error.localizedDescription)")
            return
        }
    }

    func socket(_ sock: GCDAsyncSocket, didConnectToHost _: String, port _: UInt16) {
        // 连接成功
        if let _ = connectSockets.filter({ $0.remoteSocket == sock || $0.clientSocket == sock }).first {
            // 远端或者客户端连接成功，读取数据
            print("TCPForwarder remoteSocket didConnect")
            sock.readData(withTimeout: -1, tag: 0)
        } else if sock == localListenSocket {
            print("TCPForwarder localListenSocket didConnect")
        }
    }

    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: (any Error)?) {
        if let index = connectSockets.firstIndex(where: { $0.clientSocket == sock }), index >= 0 {
            // 客户端断开连接
            print("TCPForwarder clientSocket socketDidDisconnect \(err?.localizedDescription ?? "nil") \(connectSockets.count):\(index)")
            if connectSockets.count > index {
                let item = connectSockets[index]
                item.disconnect()
                connectSockets.remove(at: index)
            }
        } else if let item = connectSockets.filter({ $0.remoteSocket == sock }).first {
            // 远程断开连接，同时断开客户端连接
            item.disconnect()
        } else if sock == localListenSocket {
            print("TCPForwarder localListenSocket socketDidDisconnect \(err?.localizedDescription ?? "nil")")
        }
    }

    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag _: Int) {
        if let item = connectSockets.filter({ $0.remoteSocket == sock }).first {
            // 如果是来自远程的数据，则转发到本地监听Socket
            item.clientSocket.write(data, withTimeout: -1, tag: 0)
        } else if let item = connectSockets.filter({ $0.clientSocket == sock }).first {
            // 如果是来自本地的数据，则转发到远程Socket
            item.remoteSocket.write(data, withTimeout: -1, tag: 0)
            print("TCPForwarder didRead localListenSocket \(data.count)")
        }
        // 继续监听数据
        sock.readData(withTimeout: -1, tag: 0)
    }
}
