import Foundation

protocol BridgingComponent: AnyObject {
    static var name: String { get }
    var delegate: BridgeDelegate { get }
    
    init(destination: BridgeDestination,
         delegate: BridgeDelegate)
    
    func handle(message: Message)
    func onViewDidLoad()
    func onViewWillAppear()
    func onViewDidAppear()
    func onViewWillDisappear()
    func onViewDidDisappear()
}

open class BridgeComponent: BridgingComponent {
    open class var name: String {
        fatalError("BridgeComponent subclass must provide a unique 'name'")
    }
    
    public unowned let delegate: BridgeDelegate
    
    required public init(destination: BridgeDestination, delegate: BridgeDelegate) {
        self.delegate = delegate
    }
    
    open func handle(message: Message) {
        fatalError("BridgeComponent subclass must handle incoming messages")
    }
    
    public func send(message: Message) {
        guard let bridge = delegate.bridge else {
            debugLog("bridgeMessageFailedToSend: bridge is not available")
            return
        }
        
        bridge.send(message)
    }
    
    open func onViewDidLoad() {}
    open func onViewWillAppear() {}
    open func onViewDidAppear() {}
    open func onViewWillDisappear() {}
    open func onViewDidDisappear() {}
}