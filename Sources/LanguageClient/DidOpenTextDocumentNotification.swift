//
//  DidOpenTextDocumentNotification.swift
//  Editor
//
//  Created by pmacro on 05/02/2019.
//

import Foundation

public struct DidOpenTextDocumentNotification: JSONRPCMessage {

  public var jsonrpc: String?
  public var id: String?
  
  public let method = "textDocument/didOpen"
  public let params: DidOpenTextDocumentParams
  
  public init(textDocument: TextDocumentItem) {
    self.params = DidOpenTextDocumentParams(textDocument: textDocument)
  }
}

public struct DidOpenTextDocumentParams: Encodable {
  public let textDocument: TextDocumentItem
  
  public init(textDocument: TextDocumentItem) {
    self.textDocument = textDocument
  }
}

public class TextDocumentItem: Encodable {
  
  /// The text document's URI.
  public let uri: String
  
  /// The text document's language identifier.
  public let languageId: String
  
  /// The version number of this document (it will strictly increase after each
  /// change, including undo/redo).
  public let version: Int
  
  /// The content of the opened text document.
  public let text: String

  public init(uri: String, languageId: String, version: Int, text: String) {
    self.uri = uri
    self.languageId = languageId
    self.version = version
    self.text = text
  }
}
