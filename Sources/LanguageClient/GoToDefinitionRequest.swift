//
//  GoToDefinitionRequest.swift
//  LanguageClient
//
//  Created by pmacro on 26/03/2019.
//

import Foundation

public struct GoToDefinitionRequest: JSONRPCMessage {

  public var jsonrpc: String?
  public var id: String?

  public var method: String = "textDocument/definition"
  public let params: TextDocumentPositionParams
  
  public init(params: TextDocumentPositionParams) {
    self.params = params
  }
}
