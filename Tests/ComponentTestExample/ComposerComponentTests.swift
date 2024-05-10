import XCTest
import WebKit
import Strada

@MainActor
final class ComposerComponentTests: XCTestCase {
    private var delegate: BridgeDelegateSpy!
    private var destination: AppBridgeDestination!
    private var component: ComposerComponent!
    private lazy var connectMessage = Message(id: "1",
                                              component: ComposerComponent.name,
                                              event: "connect",
                                              metadata: .init(url: "https://37signals.com"),
                                              jsonData: connectMessageJsonData)
    private let connectMessageJsonData = """
    [
       {
          "email":"user@37signals.com",
          "index":0,
          "selected":true
       },
       {
          "email":"user1@37signals.com",
          "index":1,
          "selected":false
       },
       {
          "email":"user2@37signals.com",
          "index":2,
          "selected":false
       }
    ]
    """
    
    override func setUp() async throws {
        delegate = BridgeDelegateSpy()
        destination = AppBridgeDestination()
        component = ComposerComponent(destination: destination, delegate: delegate)
    }
    
    // MARK: Retreive sender tests
    
    func test_connectMessageContainsSelectedSender() {
        component.didReceive(message: connectMessage)
        
        XCTAssertEqual(component.selectedSender(), "user@37signals.com")
    }
    
    // MARK: Select sender tests
    
    func test_selectSender_emailFound_sendsTheCorrectMessageReply() async throws {
        component.didReceive(message: connectMessage)
        
        try await component.selectSender(emailAddress: "user1@37signals.com")

        let expectedMessage = connectMessage.replacing(event: "select-sender",
                                                       jsonData: "{\"selectedIndex\":1}")
        XCTAssertTrue(delegate.replyWithMessageWasCalled)
        XCTAssertEqual(delegate.replyWithMessageArg, expectedMessage)
    }
    
    func test_selectSender_emailNotFound_doesNotSendAnyMessage() async throws {
        component.didReceive(message: connectMessage)
        
        try await component.selectSender(emailAddress: "test@37signals.com")

        XCTAssertFalse(delegate.replyWithMessageWasCalled)
        XCTAssertNil(delegate.replyWithMessageArg)
    }
    
    func test_selectSender_beforeConnectMessage_doesNotSendAnyMessage() async throws {
        try await component.selectSender(emailAddress: "user1@37signals.com")

        XCTAssertFalse(delegate.replyWithMessageWasCalled)
        XCTAssertNil(delegate.replyWithMessageArg)
    }
}
