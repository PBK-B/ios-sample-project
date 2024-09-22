// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public final class HostAddressQuery {
    public let name: String

    private var host: CFHost
    weak var delegate: HostAddressQueryDelegate?
    private var targetRunLoop: RunLoop?

    init(domainName: String, delegate: HostAddressQueryDelegate? = nil) {
        self.delegate = delegate
        name = domainName
        host = CFHostCreateWithName(nil, name as CFString).takeRetainedValue()
    }

    public func start() {
        precondition(targetRunLoop == nil)
        targetRunLoop = RunLoop.current

        var context = CFHostClientContext()
        context.info = Unmanaged.passRetained(self).toOpaque()
        var success = CFHostSetClient(host, { (_: CFHost, _: CFHostInfoType, _ streamErrorPtr: UnsafePointer<CFStreamError>?, _ info: UnsafeMutableRawPointer?) in
            // print("tzmax: HostAddressQuery start callback")
            let obj = Unmanaged<HostAddressQuery>.fromOpaque(info!).takeUnretainedValue()
            if let streamError = streamErrorPtr?.pointee, streamError.domain != 0 || streamError.error != 0 {
                obj.stop(streamError: streamError, notify: true)
            } else {
                obj.stop(streamError: nil, notify: true)
            }
        }, &context)
        // print("tzmax: HostAddressQuery start \(success)")
        // assert(success)
        CFHostScheduleWithRunLoop(host, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)

        var streamError = CFStreamError()
        success = CFHostStartInfoResolution(host, .addresses, &streamError)
        if !success {
            stop(streamError: streamError, notify: true)
        }
    }

    public func cancel() {
        if targetRunLoop != nil {
            stop(error: NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError), notify: false)
        }
    }

    private func stop(error: Error?, notify: Bool) {
        precondition(RunLoop.current == targetRunLoop)
        targetRunLoop = nil

        CFHostSetClient(host, nil, nil)
        CFHostUnscheduleFromRunLoop(host, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        CFHostCancelInfoResolution(host, .addresses)
        Unmanaged.passUnretained(self).release()

        if notify {
            if let error = error {
                delegate?.didComplete(error: error, hostAddressQuery: self)
            } else {
                let addresses = CFHostGetAddressing(host, nil)!.takeUnretainedValue() as NSArray as! [Data]
                delegate?.didComplete(addresses: addresses, hostAddressQuery: self)
            }
        }
    }

    private func stop(streamError: CFStreamError?, notify: Bool) {
        let error: Error?
        if let streamError = streamError {
            // Convert a CFStreamError to a NSError.  This is less than ideal because I only handle
            // a limited number of error domains.  Wouldn't it be nice if there was a public API to
            // do this mapping <rdar://problem/5845848> or a CFHost API that used CFError
            // <rdar://problem/6016542>.
            switch streamError.domain {
            case CFStreamErrorDomain.POSIX.rawValue:
                error = NSError(domain: NSPOSIXErrorDomain, code: Int(streamError.error))
            case CFStreamErrorDomain.macOSStatus.rawValue:
                error = NSError(domain: NSOSStatusErrorDomain, code: Int(streamError.error))
            case Int(kCFStreamErrorDomainNetServices):
                error = NSError(domain: kCFErrorDomainCFNetwork as String, code: Int(streamError.error))
            case Int(kCFStreamErrorDomainNetDB):
                error = NSError(domain: kCFErrorDomainCFNetwork as String, code: Int(CFNetworkErrors.cfHostErrorUnknown.rawValue), userInfo: [
                    kCFGetAddrInfoFailureKey as String: streamError.error as NSNumber,
                ])
            default:
                // If it's something we don't understand, we just assume it comes from
                // CFNetwork.
                error = NSError(domain: kCFErrorDomainCFNetwork as String, code: Int(streamError.error))
            }
        } else {
            error = nil
        }
        stop(error: error, notify: notify)
    }
}

public protocol HostAddressQueryDelegate: AnyObject {
    /// Called when the query completes successfully.
    ///
    /// This is called on the same thread that called `start()`.
    ///
    /// - Parameters:
    ///   - addresses: The addresses for the DNS name.  This has some important properties:
    ///     - It will not be empty.
    ///     - Each element is a `Data` value that contains some flavour of `sockaddr`
    ///     - It can contain any combination of IPv4 and IPv6 addresses
    ///     - The addresses are sorted, with the most preferred first
    ///   - query: The query that completed.
    func didComplete(addresses: [Data], hostAddressQuery query: HostAddressQuery)

    /// Called when the query completes with an error.
    ///
    /// This is called on the same thread that called `start()`.
    ///
    /// - Parameters:
    ///   - error: An error describing the failure.
    ///   - query: The query that completed.
    ///
    /// - Important: In most cases the error will be in domain `kCFErrorDomainCFNetwork`
    ///   with a code of `kCFHostErrorUnknown` (aka `CFNetworkErrors.cfHostErrorUnknown`),
    ///   and the user info dictionary will contain an element with the `kCFGetAddrInfoFailureKey`
    ///   key whose value is an NSNumber containing an `EAI_XXX` value (from `<netdb.h>`).

    func didComplete(error: Error, hostAddressQuery query: HostAddressQuery)
}
