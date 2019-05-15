//
//  JSONRPCMessageSender.swift
//  LanguageClient
//
//  Created by pmacro on 15/05/2019.
//

import Foundation
import PromiseKit

///
/// An entity that can send JSON RPC messages.
///
public protocol JSONRPCMessageSender {
  func send<T: JSONRPCMessage, R: JSONRPCResult>(message: T,
                                                 responseType: R.Type) -> Promise<R>
  func send<T: JSONRPCMessage>(notification: T)
}
