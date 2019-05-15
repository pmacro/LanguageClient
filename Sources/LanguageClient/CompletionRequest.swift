//
//  CompletionRequest.swift
//  Editor
//
//  Created by pmacro on 05/02/2019.
//

import Foundation

public struct CompletionRequest: JSONRPCMessage {
  public var jsonrpc: String?
  public var id: String?
  
  public let method = "textDocument/completion"
  public let params: TextDocumentPositionParams
  
  public init(params: TextDocumentPositionParams) {
    self.params = params
  }
}

public struct TextDocumentPositionParams: Encodable {

  /// The text document.
  public let textDocument: TextDocumentIdentifier
  

  /// The position inside the text document.
  public let position: Position
  
  public init(textDocument: TextDocumentIdentifier, position: Position) {
    self.textDocument = textDocument
    self.position = position
  }
}

public struct TextDocumentIdentifier: Encodable {
  public let uri: String
  
  public init(uri: String) {
    self.uri = uri
  }
}
