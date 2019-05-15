//
//  InitializeResponse.swift
//  Editor
//
//  Created by pmacro on 05/02/2019.
//

import Foundation

public struct InitializeResult: JSONRPCResult {
  ///
  /// The capabilities the language server provides.
  ///
  public let capabilities: ServerCapabilities
}

public enum TextDocumentSync: Decodable {
  case kind(TextDocumentSyncKind)
  case options(TextDocumentSyncOptions)
  
  public init(from decoder: Decoder) throws {
    if let kind = try? decoder.singleValueContainer().decode(TextDocumentSyncKind.self) {
      self = .kind(kind)
      return
    }
    
    if let options = try? decoder.singleValueContainer().decode(TextDocumentSyncOptions.self) {
      self = .options(options)
      return
    }
    
    self = .kind(.none)
  }
  
  public var syncKind: TextDocumentSyncKind {
    switch self {
    case .kind(let kind):
      return kind
    case .options(let options):
      return options.change ?? .none
    }
  }
}

public struct ServerCapabilities: Decodable {
  
  /// Defines how text documents are synced.
  public let textDocumentSync: TextDocumentSync
  
  /// The server provides hover support.
  public let hoverProvider: Bool?

  /// The server provides completion support.
  public let completionProvider: CompletionOptions?

  /// The server provides signature help support.
  public let signatureHelpProvider: SignatureHelpOptions?

  /// The server provides goto definition support.
  public let definitionProvider: Bool?
  
  /// The server provides find references support.
  public let referencesProvider: Bool?
  
  /// The server provides document highlight support.
  public let documentHighlightProvider: Bool?
  
  /// The server provides document symbol support.
  public let documentSymbolProvider: Bool?
  
  /// The server provides workspace symbol support.
  public let workspaceSymbolProvider: Bool?
  
  /// The server provides code actions.
  public let codeActionProvider: Bool?

  /// The server provides code lens.
  public let codeLensProvider: CodeLensOptions?
  
  /// The server provides document formatting.
  public let documentFormattingProvider: Bool?
  
  /// The server provides document range formatting.
  public let documentRangeFormattingProvider: Bool?
  
  /// The server provides document formatting on typing.
  public let documentOnTypeFormattingProvider: DocumentOnTypeFormattingOptions?
  
  /// The server provides rename support.
  public let renameProvider: Bool?
}

public struct TextDocumentSyncOptions: Decodable {
  ///
  /// Open and close notifications are sent to the server.
  ///
  public let openClose: Bool?
  
  ///
  /// Change notifications are sent to the server. See TextDocumentSyncKind.None,
  /// TextDocumentSyncKind.Full
  /// and TextDocumentSyncKind.Incremental. If omitted it defaults to TextDocumentSyncKind.None.
  ///
  public let change: TextDocumentSyncKind?
  
  ///
  /// Will save notifications are sent to the server.
  ///
  public let willSave: Bool?
  
  ///
  /// Will save wait until requests are sent to the server.
  ///
  public let willSaveWaitUntil: Bool?
  
  ///
  /// Save notifications are sent to the server.
  ///
  public let save: SaveOptions?
}

public struct SaveOptions: Decodable {
  ///
  /// The client is supposed to include the content on save.
  ///
  public let includeText: Bool?
}

///
/// Defines how the host (editor) should sync document changes to the language server.
///
public enum TextDocumentSyncKind: Int, Decodable {
  
  /// Documents should not be synced at all.
  case none = 0

  /// Documents are synced by always sending the full content of the document.
  case full = 1

  /// Documents are synced by sending the full content on open. After that only incremental
  /// updates to the document are sent.
  case incremental = 2
}

public struct CompletionOptions: Decodable {
  
  /// The server provides support to resolve additional information for a completion item.
  public let resolveProvider: Bool?
  
  /// The characters that trigger completion automatically.
  public let triggerCharacters: [String]?
}

public struct SignatureHelpOptions: Decodable {

  /// The characters that trigger signature help automatically.
  public let triggerCharacters: [String]?
}

public struct CodeLensOptions: Decodable {

  /// Code lens has a resolve provider as well.
  public let resolveProvider: Bool?
}

///
/// Format document on type options
///
public struct DocumentOnTypeFormattingOptions: Decodable {

  /// A character on which formatting should be triggered, like `}`.
  public let firstTriggerCharacter: String
  
  /// More trigger characters.
  public let moreTriggerCharacter: [String]?
}

public struct InitializeError: Decodable {
  ///
  /// Indicates whether the client should retry to send the
  /// initialize request after showing the message provided
  /// in the ResponseError.
  ///
  public let retry: Bool
}
