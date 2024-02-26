import WebKit

protocol ScriptMessageHandlerDelegate: AnyObject {
    func scriptMessageHandlerDidReceiveMessage(_ scriptMessage: WKScriptMessage) async throws
}

// Avoids retain cycle caused by WKUserContentController
final class ScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: ScriptMessageHandlerDelegate?
    
    init(delegate: ScriptMessageHandlerDelegate?) {
        self.delegate = delegate
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive scriptMessage: WKScriptMessage) {
        Task { try await delegate?.scriptMessageHandlerDidReceiveMessage(scriptMessage) }
    }
}
