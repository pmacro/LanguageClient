//
//  LogMessage.swift
//  LanguageClient
//
//  Created by pmacro on 27/02/2019.
//

import Foundation

public struct LogMessage: Decodable {
  /// The range at which the message applies.
  public let params: LogMessageParams
}

public struct LogMessageParams: Decodable {
  
  ///
  /// The message type.
  ///
  public let type: MessageType

  /// The log message text.
  public let message: String
}

public enum MessageType: Int, Decodable {
  /// An error message.
  case error = 1
  
  /// A warning message.
  case warning = 2
  
  /// An information message.
  case info = 3
  
  /// A log message.
  case log = 4
}

