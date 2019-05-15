//
//  JSONRPCMessage.swift
//  LanguageClient
//
//  Created by pmacro on 15/05/2019.
//

import Foundation

///
/// A message that can be sent over JSON RPC.
///
public protocol JSONRPCMessage: Encodable {
  var method: String { get }
  var jsonrpc: String? { get set }
  var id: String? { get set }
}
