import HandyOperators
import SystemConfiguration

@MainActor
final class ReachabilityTracker {
	typealias Flags = SCNetworkReachabilityFlags
	
	static let shared = ReachabilityTracker()
	
	let base: SCNetworkReachability
	var flags: SCNetworkReachabilityFlags
	var reachabilityChanged: (@MainActor (Flags, Flags) -> Void)?
	
	private init() {
		// this is a super old C api we're wrapping; the code will look a bit weird
		
		// a zero address lets us monitor the connection to the internet without looking at any server in particular
		let address = sockaddr() <- {
			// TODO: is this necessary?
			$0.sa_len = .init(MemoryLayout<sockaddr>.size)
			$0.sa_family = .init(AF_INET)
		}
		let base = withUnsafePointer(to: address) { address in
			SCNetworkReachabilityCreateWithAddress(nil, address)!
		}
		self.base = base
		self.flags = .init() <- {
			SCNetworkReachabilityGetFlags(base, &$0)
		}
		
		let wasSet = SCNetworkReachabilitySetCallback(base, { _, flags, _ in
			ReachabilityTracker.shared.callback(flags: flags)
		}, nil)
		assert(wasSet)
		
		let wasScheduled = SCNetworkReachabilityScheduleWithRunLoop(base, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
		assert(wasScheduled)
	}
	
	private func callback(flags: Flags) {
		if #available(iOS 17.0, *) {
			MainActor.assertIsolated()
		}
		
		reachabilityChanged?(self.flags, flags)
		self.flags = flags
	}
}

extension ReachabilityTracker.Flags {
	var isReachable: Bool { contains(.reachable) }
	var isOnCellular: Bool { contains(.isWWAN) }
}
