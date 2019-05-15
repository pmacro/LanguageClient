//
//  Diagnostics.swift
//  Editor
//
//  Created by pmacro on 05/02/2019.
//

import Foundation

public struct Diagnostics: JSONRPCResult {
  let params: DiagnosticsParams
}

public struct DiagnosticsParams: Decodable {
  let uri: String
  let diagnostics: [Diagnostic]
}

public struct Diagnostic: Decodable {
  /// The range at which the message applies.
  public let range: ContentRange
  
  /// The diagnostic's severity. Can be omitted. If omitted it is up to the
  /// client to interpret diagnostics as error, warning, info or hint.
  public let severity: Int?
  
  /// The diagnostic's code. Can be omitted.
  public let code: String?
  
  /// A human-readable string describing the source of this
  /// diagnostic, e.g. 'typescript' or 'super lint'.
  public let source: String?
  
  /// The diagnostic's message.
  public let message: String
}
