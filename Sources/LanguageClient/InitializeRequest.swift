//
//  InitializeRequest.swift
//  BrightFutures
//
//  Created by pmacro on 05/02/2019.
//

import Foundation

struct InitializeRequest: JSONRPCMessage {

  var jsonrpc: String?
  var id: String?
  
  let method = "initialize"
  let params: InitializeParams
  
  init(params: InitializeParams) {
    self.params = params
  }
}

struct InitializeParams: Encodable {
  
  ///
  /// The process Id of the parent process that started
  /// the server. Is null if the process has not been started by another process.
  /// If the parent process is not alive then the server should exit (see exit notification)
  /// its process.
  ///
  let processId: Int32?
  
  ///
  /// The rootPath of the workspace. Is null
  /// if no folder is open.
  ///
  let rootPath: String?
  
  ///
  /// User provided initialization options.
  ///
//  let initializationOptions: AnyObject?
  
  ///
  /// The capabilities provided by the client (editor)
  ///
  let capabilities: ClientCapabilities
}

public struct ClientCapabilities: Encodable {

  /// Workspace specific client capabilities.
  public var workspace: WorkspaceClientCapabilities? = nil
  
  /// Text document specific client capabilities.
  public var textDocument: TextDocumentClientCapabilities = TextDocumentClientCapabilities()
}

public struct WorkspaceClientCapabilities: Encodable {
  
}

public struct TextDocumentClientCapabilities: Encodable {
  
  /**
   * Capabilities specific to the `textDocument/definition`.
   *
   * Since 3.14.0
   */
  let definition = DefinitionCapabilitiesConfiguration()
  
}

public struct DefinitionCapabilitiesConfiguration: Encodable {
  /**
   * Whether definition supports dynamic registration.
   */
  var dynamicRegistration = false
  
  /**
   * The client supports additional metadata in the form of definition links.
   */
  var linkSupport = true
}
