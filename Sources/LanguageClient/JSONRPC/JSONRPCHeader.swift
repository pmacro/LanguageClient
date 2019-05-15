//
//  JSONRPCHeader.swift
//  LanguageClient
//
//  Created by pmacro on 15/05/2019.
//

import Foundation

///
/// Represents the header from a JSON RPC message.
///
public struct JSONRPCHeader {
  
  /// The content length from the header.
  let contentLength: Int
  
  ///
  /// Create a JSONRPCHeader from a header string.
  ///
  init(from string: String) {
    let fields = string.split(separator: "\n")
    var length = 0
    
    for field in fields {
      let keyValuePair = field.split(separator: ":")
      
      if keyValuePair.count == 2 {
        let value = keyValuePair[1].trimmingCharacters(in: .whitespacesAndNewlines)
        
        if keyValuePair[0] == "Content-Length" {
          length = Int(value) ?? length
        }
      }
    }
    
    self.contentLength = length
  }
}
