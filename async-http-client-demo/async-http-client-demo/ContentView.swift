//
//  ContentView.swift
//  async-http-client-demo
//
//  Created by Bin on 2023/8/27.
//

import AsyncHTTPClient
import NIOCore
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world! 666")
            Button("Get Data", action: getData)
        }
        .padding()
    }

    func getData() {
        Task {
            do {
                let client = HTTPClient(eventLoopGroupProvider: .singleton)
                var request = HTTPClientRequest(url: "https://xkcd.com/info.0.json")

                request.body = .bytes(.init(string: "hello"))
                let response = try await client.execute(request, timeout: .seconds(30))
                if response.status == .ok {
                    var body = try await response.body.collect(upTo: 1024 * 1024) // 1 MB
                    if let bytes = body.readBytes(length: body.readableBytes) {
                        print("body: \(String(bytes: bytes, encoding: .utf8))")
                    }
                } else {
                    // handle remote error
                    print("error: \(response.status)")
                }
                try await client.shutdown()
            } catch {
                print("error: \(error)")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
