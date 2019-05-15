import XCTest
@testable import LanguageClient

class LanguageServerTests: XCTestCase {
  
  let languageServerPath = URL(fileURLWithPath: "/Users/pmacrory/dev/ui/sourcekit-lsp/.build/x86_64-apple-macosx/debug/sourcekit-lsp")
      .standardizedFileURL.absoluteString
  
  let packagePath = URL(fileURLWithPath: #file + "../../../../TestPackage/")
                    .standardizedFileURL.absoluteString

  var sourcePath: String {
    return packagePath + "/Sources/TestPackage/"
  }
  
  func createLanguageClient() -> LanguageClient {
    let client = LanguageClient()
    let expectation = XCTestExpectation(description: "Wait for server capabilities")
    
    _ = client.startServer(atPath: languageServerPath, sourcePath: packagePath)
      .done { result in
      if client.capabilities != nil {
        expectation.fulfill()
        return
      }
      
      XCTFail("Start server failed with unexpected result.")
    }
    
    wait(for: [expectation], timeout: 5)
    return client
  }
  
  func testInitialisation() {
    _ = createLanguageClient()
  }
  
  func testFileOpenAndDiagnostics() {
    let client = createLanguageClient()
    
    let document = TextDocumentItem(uri: sourcePath + "/main.swift",
                                    languageId: "swift",
                                    version: 1,
                                    text: """
                                            func hello() {
                                              print("World"
                                            }
                                          """)
    let openMessage = DidOpenTextDocumentNotification(textDocument: document)
    
    let expectation = XCTestExpectation(description: "Wait for diagnostics")

    let testDelegate = TestDelegate(expectation: expectation)
    client.register(testDelegate, forURI: document.uri)
    
    client.send(notification: openMessage)
    
    wait(for: [expectation], timeout: 10)
    XCTAssert(!testDelegate.diagnostics.isEmpty)
  }
  
  func testCodeCompletionHasResults() {
    let client = createLanguageClient()
    
    let document = TextDocumentItem(uri: sourcePath + "/main.swift",
                                    languageId: "swift",
                                    version: 1,
                                    text: """
                                          func hello() {
                                            let i = 0;
                                            let j = i.
                                          }
                                          """)
    let openMessage = DidOpenTextDocumentNotification(textDocument: document)
    
    let expectation = XCTestExpectation(description: "Wait for diagnostics")
    let testDelegate = TestDelegate(expectation: expectation)
    client.register(testDelegate, forURI: document.uri)
    client.send(notification: openMessage)
    wait(for: [expectation], timeout: 10)

    let completionExpectation = XCTestExpectation(description: "Completion Expectation")
    
    let documentIdentifier = TextDocumentIdentifier(uri: document.uri)
    let completionMessage
      = CompletionRequest(params: TextDocumentPositionParams(textDocument: documentIdentifier,
                                                             position: Position(line: 2,
                                                                                character: 12)))
    
    _ = client.send(message: completionMessage, responseType: CompletionResult.self)
      .done { result in
      if !result.items.isEmpty {
        completionExpectation.fulfill()
      }
    }
    .catch{ error in
      XCTFail("Bad completion response.")
    }
    
    wait(for: [completionExpectation], timeout: 10)
  }
  
  func testCodeCompletionMethodCompletion() {
    let client = createLanguageClient()
    
    let document = TextDocumentItem(uri: sourcePath + "/main.swift",
                                    languageId: "swift",
                                    version: 1,
                                    text: """
                                          func hello() {
                                            print("Hello!")
                                          }

                                          hel
                                          """)
    let openMessage = DidOpenTextDocumentNotification(textDocument: document)
    client.send(notification: openMessage)
    
    let completionExpectation = XCTestExpectation(description: "Completion Expectation")
    
    let documentIdentifier = TextDocumentIdentifier(uri: document.uri)
    let completionMessage
      = CompletionRequest(params: TextDocumentPositionParams(textDocument: documentIdentifier,
                                                             position: Position(line: 4,
                                                                                character: 3)))
    
    _ = client.send(message: completionMessage, responseType: CompletionResult.self)
      .done { result in
        if !result.items.isEmpty {
          if result.items.contains(where: { $0.label.contains("hello()") }) {
            completionExpectation.fulfill()
          } else {
            XCTFail("Got completion results, but they didn't contain method hello() ☹️.")
          }
        }
      }
      .catch{ error in
        XCTFail("Bad completion response.")
    }
    
    wait(for: [completionExpectation], timeout: 1000)
  }
  
  func testBadOffsetsDontCrash() {
    let client = createLanguageClient()
    let document = TextDocumentItem(uri: sourcePath + "/main.swift",
                                    languageId: "swift",
                                    version: 1,
                                    text: "")
    let openMessage = DidOpenTextDocumentNotification(textDocument: document)
    client.send(notification: openMessage)

    Thread.sleep(forTimeInterval: 1)
    
    let changeEvent = TextDocumentContentChangeEvent(range: ContentRange(start: Position(line: 0,
                                                                                         character: 0),
                                                                         end: Position(line: 0,
                                                                                       character: 0)),
                                                     rangeLength: 2,
                                                     text: "\"\"")
    let textChangeParams = DidChangeTextDocumentParams(textDocument: VersionedTextDocumentIdentifier(version: 1,
                                                                                               uri: document.uri),
                                                 
                                                 contentChanges: [changeEvent])
    
    client.send(notification: DidChangeTextDocumentNotification(params: textChangeParams))
  }
}

class TestDelegate: LanguageClientNotificationDelegate {
  
  var diagnostics: [Diagnostic] = []
  let expectation: XCTestExpectation
  
  init(expectation: XCTestExpectation) {
    self.expectation = expectation
  }
  
  func receive(diagnostics: [Diagnostic]) {
    self.diagnostics = diagnostics
    expectation.fulfill()
  }
}
