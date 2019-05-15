//
//  DidCloseTextDocumentNotification.swift
//  LanguageClient
//
//  Created by pmacro on 13/03/2019.
//

import Foundation

public struct DidCloseTextDocumentNotification: JSONRPCMessage {
  
  public var jsonrpc: String?
  public var id: String?
  
  public let method = "textDocument/didClose"
  public let params: DidCloseTextDocumentParams
  
  public init(textDocumentIdentifier: TextDocumentIdentifier) {
    self.params = DidCloseTextDocumentParams(textDocumentIdentifier: textDocumentIdentifier)
  }
}

public struct DidCloseTextDocumentParams: Encodable {
  public let textDocument: TextDocumentIdentifier
  
  public init(textDocumentIdentifier: TextDocumentIdentifier) {
    self.textDocument = textDocumentIdentifier
  }
}
