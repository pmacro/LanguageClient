//
//  JSONRPCResult.swift
//  LanguageClient
//
//  Created by pmacro on 15/05/2019.
//

import Foundation

/// A response for a JSON RPC message.
public protocol JSONRPCResult: Decodable {}

/// A closure containing the type-aware code that upon receiving a response will convert
/// `Data` into the correct type before sending the response.
typealias JSONRPCPendingResult = (Data) -> Void

///
/// A result from a JSON RPC call, with a decodable result type within.
///
struct JSONRPCWrappedResult<T: Decodable>: Decodable {
  let result: T?
}

///
/// A struct that can be used to decode a JSON RPC result in order to read
/// its method and ID.
///
struct JSONRPCResultPeeker: Decodable {
  let method: String?
  let id: String?
}
