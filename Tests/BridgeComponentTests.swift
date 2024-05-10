import Foundation
import XCTest
import WebKit
import Strada

@MainActor
class BridgeComponentTest: XCTestCase {
    private var delegate: BridgeDelegateSpy!
    private var destination: AppBridgeDestination!
    private var component: OneBridgeComponent!
    private let message = Message(id: "1",
                                  component: OneBridgeComponent.name,
                                  event: "connect",
                                  metadata: .init(url: "https://37signals.com"),
                                  jsonData: "{\"title\":\"Page-title\",\"subtitle\":\"Page-subtitle\"}")
    
    override func setUp() async throws {
        destination = AppBridgeDestination()
        delegate = BridgeDelegateSpy()
        component = OneBridgeComponent(destination: destination, delegate: delegate)
        component.didReceive(message: message)
    }
    
    // MARK: didReceive(:) and caching
    
    func test_didReceiveCachesTheMessage() {
        let cachedMessage = component.receivedMessage(for: "connect")
        XCTAssertEqual(cachedMessage, message)
    }
    
    func test_didReceiveCachesOnlyTheLastMessage() {
        let newJsonData = "{\"title\":\"Page-title\"}"
        let newMessage = message.replacing(jsonData: newJsonData)
        
        component.didReceive(message: newMessage)
        
        let cachedMessage = component.receivedMessage(for: "connect")
        XCTAssertEqual(cachedMessage, newMessage)
    }
    
    func test_retrievingNonCachedMessageForEvent() {
        let cachedMessage = component.receivedMessage(for: "disconnect")
        XCTAssertNil(cachedMessage)
    }
    
    // MARK: reply(to:)
    
    func test_replyToReceivedMessageSucceeds() async throws {
        let success = try await component.reply(to: "connect")

        XCTAssertTrue(success)
        XCTAssertTrue(delegate.replyWithMessageWasCalled)
        XCTAssertEqual(delegate.replyWithMessageArg, message)
    }
    
    func test_replyToReceivedMessageWithACodableObjectSucceeds() async throws {
        let messageData = MessageData(title: "hey", subtitle: "", actionName: "tap")
        let newJsonData = "{\"title\":\"hey\",\"subtitle\":\"\",\"actionName\":\"tap\"}"
        let newMessage = message.replacing(jsonData: newJsonData)
        
        let success = try await component.reply(to: "connect", with: messageData)

        XCTAssertTrue(success)
        XCTAssertTrue(delegate.replyWithMessageWasCalled)
        XCTAssertEqual(delegate.replyWithMessageArg, newMessage)
    }
    
    func test_replyToMessageNotReceivedWithACodableObjectIgnoresTheReply() async throws {
        let messageData = MessageData(title: "hey", subtitle: "", actionName: "tap")
        
        let success = try await component.reply(to: "disconnect", with: messageData)

        XCTAssertFalse(success)
        XCTAssertFalse(delegate.replyWithMessageWasCalled)
        XCTAssertNil(delegate.replyWithMessageArg)
    }
    
    func test_replyToMessageNotReceivedIgnoresTheReply() async throws {
        let success = try await component.reply(to: "disconnect")

        XCTAssertFalse(success)
        XCTAssertFalse(delegate.replyWithMessageWasCalled)
        XCTAssertNil(delegate.replyWithMessageArg)
    }
    
    func test_replyToMessageNotReceivedWithJsonDataIgnoresTheReply() async throws {
        let success = try await component.reply(to: "disconnect", with: "{\"title\":\"Page-title\"}")

        XCTAssertFalse(success)
        XCTAssertFalse(delegate.replyWithMessageWasCalled)
        XCTAssertNil(delegate.replyWithMessageArg)
    }

    // MARK: reply(to:) non-async

    func test_replyToReceivedMessageSucceeds() {
        let expectation = expectation(description: "Wait for completion.")

        component.reply(to: "connect") { [unowned self] result in
            switch result {
            case .success(let success):
                XCTAssert(success)
                XCTAssertTrue(delegate.replyWithMessageWasCalled)
                XCTAssertEqual(delegate.replyWithMessageArg, message)
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: .expectationTimeout)
    }
    
    func test_replyToReceivedMessageWithACodableObjectSucceeds() {
        let messageData = MessageData(title: "hey", subtitle: "", actionName: "tap")
        let newJsonData = "{\"title\":\"hey\",\"subtitle\":\"\",\"actionName\":\"tap\"}"
        let newMessage = message.replacing(jsonData: newJsonData)
        let expectation = expectation(description: "Wait for completion.")

        component.reply(to: "connect", with: messageData) { [unowned self] result in
            switch result {
            case .success(let success):
                XCTAssertTrue(success)
                XCTAssertTrue(delegate.replyWithMessageWasCalled)
                XCTAssertEqual(delegate.replyWithMessageArg, newMessage)
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: .expectationTimeout)
    }
    
    func test_replyToMessageNotReceivedWithACodableObjectIgnoresTheReply() {
        let messageData = MessageData(title: "hey", subtitle: "", actionName: "tap")
        let expectation = expectation(description: "Wait for completion.")

        component.reply(to: "disconnect", with: messageData) { [unowned self] result in
            switch result {
            case .success(let success):
                XCTAssertFalse(success)
                XCTAssertFalse(delegate.replyWithMessageWasCalled)
                XCTAssertNil(delegate.replyWithMessageArg)
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: .expectationTimeout)
    }
    
    func test_replyToMessageNotReceivedIgnoresTheReply() {
        let expectation = expectation(description: "Wait for completion.")

        component.reply(to: "disconnect") { [unowned self] result in
            switch result {
            case .success(let success):
                XCTAssertFalse(success)
                XCTAssertFalse(delegate.replyWithMessageWasCalled)
                XCTAssertNil(delegate.replyWithMessageArg)
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: .expectationTimeout)
    }
    
    func test_replyToMessageNotReceivedWithJsonDataIgnoresTheReply() {
        let expectation = expectation(description: "Wait for completion.")

        component.reply(to: "disconnect", with: "{\"title\":\"Page-title\"}") { [unowned self] result in
            switch result {
            case .success(let success):
                XCTAssertFalse(success)
                XCTAssertFalse(delegate.replyWithMessageWasCalled)
                XCTAssertNil(delegate.replyWithMessageArg)
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: .expectationTimeout)
    }

    // MARK: reply(with:)
   
    func test_replyWithSucceedsWhenBridgeIsSet() async throws {
        let newJsonData = "{\"title\":\"Page-title\"}"
        let newMessage = message.replacing(jsonData: newJsonData)
        
        let success = try await component.reply(with: newMessage)

        XCTAssertTrue(success)
        XCTAssertTrue(delegate.replyWithMessageWasCalled)
        XCTAssertEqual(delegate.replyWithMessageArg, newMessage)
    }

    // MARK: reply(with:) non-async

    func test_replyWithSucceedsWhenBridgeIsSet() {
        let expectation = expectation(description: "Wait for completion.")

        let newJsonData = "{\"title\":\"Page-title\"}"
        let newMessage = message.replacing(jsonData: newJsonData)

        component.reply(with: newMessage) { [unowned self] result in
            switch result {
            case .success(let success):
                XCTAssert(success)
                XCTAssertTrue(delegate.replyWithMessageWasCalled)
                XCTAssertEqual(delegate.replyWithMessageArg, newMessage)
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: .expectationTimeout)
    }
}
