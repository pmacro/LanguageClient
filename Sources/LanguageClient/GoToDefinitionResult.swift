//
//  GoToDefinitionResult.swift
//  LanguageClient
//
//  Created by pmacro on 26/03/2019.
//

import Foundation

public struct GoToDefinitionResult: JSONRPCResult {
  
  enum CodingKeys: String, CodingKey {
    case location
    case locations
    case type
  }

  public var locations: [Location]?
  public var links: [LocationLink]?
  
  public init(from decoder: Decoder) throws {
    if let location = try? Location(from: decoder) {
      locations = [location]
    }
    else if let locations = try? [Location](from: decoder) {
      self.locations = locations
    }
    else if let links = try? [LocationLink](from: decoder) {
      self.links = links
    }
  }
}

public struct Location: Codable {
  public let uri: String
  public let range: ContentRange
}

public struct LocationLink: Codable {
  /// Span of the origin of this link.
  ///
  /// Used as the underlined span for pointer interaction. Defaults to the word range at
  /// the pointer position.
  public let originSelectionRange: ContentRange?
  
  /// The target resource identifier of this link.
  public let targetUri: String
  
  /// The full target range of this link. If the target for example is a symbol then
  /// target range is the range enclosing this symbol not including leading/trailing
  /// whitespace but everything else like comments. This information is typically
  /// used to highlight the range in the editor.
  public let targetRange: ContentRange
  
  /// The range that should be selected and revealed when this link is being followed,
  /// e.g the name of a function.
  /// Must be contained by the the `targetRange`. See also `DocumentSymbol#range`
  public let targetSelectionRange: ContentRange
}

