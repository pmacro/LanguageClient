//
//  DidChangeTextDocumentNotification.swift
//  Editor
//
//  Created by pmacro on 05/02/2019.
//

import Foundation

public struct DidChangeTextDocumentNotification: JSONRPCMessage {
  public var jsonrpc: String?
  public var id: String?
  
  public let method = "textDocument/didChange"
  public let params: DidChangeTextDocumentParams
  
  public init(params: DidChangeTextDocumentParams) {
    self.params = params
  }
}

public struct DidChangeTextDocumentParams: Encodable {

  /// The document that did change. The version number points
  /// to the version after all provided content changes have
  /// been applied.
  public let textDocument: VersionedTextDocumentIdentifier
  
  /// The actual content changes.
  public let contentChanges: [TextDocumentContentChangeEvent]
  
  public init(textDocument: VersionedTextDocumentIdentifier,
              contentChanges: [TextDocumentContentChangeEvent]) {
    self.textDocument = textDocument
    self.contentChanges = contentChanges
  }
}

public struct VersionedTextDocumentIdentifier: Encodable {
  public let version: Int
  public let uri: String
  
  public init(version: Int, uri: String) {
    self.version = version
    self.uri = uri
  }
}

///
/// An event describing a change to a text document. If range and rangeLength are omitted
/// the new text is considered to be the full content of the document.
///
public struct TextDocumentContentChangeEvent: Encodable {
  
  /// The range of the document that changed.
  public let range: ContentRange?
  
  /// The length of the range that got replaced.
  public let rangeLength: Int?
  
  /// The new text of the document.
  public let text: String?
  
  public init(range: ContentRange?, rangeLength: Int?, text: String?) {
    self.range = range
    self.rangeLength = rangeLength
    self.text = text
  }
}

public struct ContentRange: Codable {
  public let start: Position
  public let end: Position
  
  public init(start: Position, end: Position) {
    self.start = start
    self.end = end
  }
}

public struct Position: Codable, Equatable {
  public let line: Int
  public let character: Int
  
  public init(line: Int, character: Int) {
    self.line = line
    self.character = character
  }
}
