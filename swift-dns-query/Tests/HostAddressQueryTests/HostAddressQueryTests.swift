@testable import HostAddressQuery
import XCTest

final class HostAddressQueryTests: XCTestCase {
    var tmpDelegate: HostAddressQueryDelegate?

    func testExample() throws {
        tmpDelegate = QueryDelegate(handling: { err, ip, _ in
            if let err {
                print("dnsQuery failed", err.localizedDescription)
                return
            }
            print("dnsQuery ip:", ip)
        })
        let dnsQuery = HostAddressQuery(domainName: "bin.zmide.com", delegate: tmpDelegate)
        dnsQuery.start()
    }

    class QueryDelegate: HostAddressQueryDelegate {
        let handling: (Error?, [String]?, HostAddressQuery?) -> Void
        public init(handling: @escaping (Error?, [String]?, HostAddressQuery?) -> Void) {
            self.handling = handling
        }

        func numeric(for address: Data) -> String {
            var name = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let saLen = socklen_t(address.count)
            let success = address.withUnsafeBytes { (sa: UnsafePointer<sockaddr>) in
                getnameinfo(sa, saLen, &name, socklen_t(name.count), nil, 0, NI_NUMERICHOST | NI_NUMERICSERV) == 0
            }
            guard success else {
                return "?"
            }
            return String(cString: name)
        }

        func didComplete(error: any Error, hostAddressQuery: HostAddressQuery) {
            handling(error, nil, hostAddressQuery)
        }

        func didComplete(addresses: [Data], hostAddressQuery: HostAddressQuery) {
            let addressList = addresses.map { self.numeric(for: $0) }
            handling(nil, addressList, hostAddressQuery)
        }
    }
}
