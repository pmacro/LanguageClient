//
//  CompletionResult.swift
//  Editor
//
//  Created by pmacro  on 05/02/2019.
//

import Foundation

extension Array: JSONRPCResult where Element == CompletionItem {}

public struct CompletionResult: JSONRPCResult {
  
  /// This list it not complete. Further typing should result in recomputing
  /// this list.
  public let isIncomplete: Bool
  
  /// The completion items.
  public let items: [CompletionItem]
  
  public init(from decoder: Decoder) throws {
    if let completionItems = try? ([CompletionItem].self).init(from: decoder) {
      self.isIncomplete = false
      self.items = completionItems
      return
    }
    
    do {
      let completionList = try CompletionList(from: decoder)
      self.isIncomplete = completionList.isIncomplete
      self.items = completionList.items
    }
  }
}

public struct CompletionList: JSONRPCResult {

  /// This list it not complete. Further typing should result in recomputing
  /// this list.
  let isIncomplete: Bool
  
  /// The completion items.
  let items: [CompletionItem]
}

public struct CompletionItem: Decodable {
  
  // TODO delete me!  Temporary testing code only.
  public init(label: String) {
    self.label = label
    self.kind = nil
    self.detail = nil
    self.documentation = nil
    self.additionalTextEdits = nil
    self.data = nil
    self.sortText = nil
    self.filterText = nil
    self.insertText = nil
    self.textEdit = nil
    self.command = nil
  }
  
  /// The label of this completion item. By default
  /// also the text that is inserted when selecting
  /// this completion.
  public let label: String
  
  /// The kind of this completion item. Based of the kind
  /// an icon is chosen by the editor.
  public let kind: CompletionItemKind?
  
  /// A human-readable string with additional information
  /// about this item, like type or symbol information.
  public let detail: String?
  
  /// A human-readable string that represents a doc-comment.
  public let documentation: String?

  /// A string that should be used when comparing this item
  /// with other items. When `falsy` the label is used.
  public let sortText: String?
  
   /// A string that should be used when filtering a set of
   /// completion items. When `falsy` the label is used.
  public let filterText: String?
  
  /// A string that should be inserted a document when selecting
  /// this completion. When `falsy` the label is used.
  public let insertText: String?
  
  /// An edit which is applied to a document when selecting
  /// this completion. When an edit is provided the value of
  /// insertText is ignored.
  public let textEdit: TextEdit?
  
  /// An optional array of additional text edits that are applied when
  /// selecting this completion. Edits must not overlap with the main edit
  /// nor with themselves.
  public let additionalTextEdits: [TextEdit]?
  
  /// An optional command that is executed *after* inserting this completion. *Note* that
  /// additional modifications to the current document should be described with the
  /// additionalTextEdits-property.
  public let command: Command?
  
  /// An data entry field that is preserved on a completion item between
  /// a completion and a completion resolve request.
  public let data: String?
}

///
/// The kind of a completion entry.
///
public enum CompletionItemKind: Int, Decodable {
  case text           = 1,
       method         = 2,
       function       = 3,
       constructor    = 4,
       field          = 5,
       variable       = 6,
       `class`        = 7,
       interface      = 8,
       module         = 9,
       property       = 10,
       unit           = 11,
       value          = 12,
       `enum`         = 13,
       keyword        = 14,
       snippet        = 15,
       color          = 16,
       file           = 17,
       reference      = 18,
       folder         = 19,
       enumMember     = 20,
       constant       = 21,
       `struct`       = 22,
       event          = 23,
       `operator`     = 24,
       typeParameter  = 25,
       unknown        = 26
}

public struct TextEdit: Decodable {
  
  /// The range of the text document to be manipulated. To insert
  /// text into a document create a range where start === end.
  public let range: ContentRange
  
  /// The string to be inserted. For delete operations use an
  /// empty string.
  public let newText: String
}


public struct Command: Decodable {
  
  /// Title of the command, like `save`.
  public let title: String

  /// The identifier of the actual command handler.
  public let command: String
  
  /// Arguments that the command handler should be
  /// invoked with.
  public let arguments: [String]?
}

extension Array where Element == CompletionItem {
  public mutating func filter(using filterText: String) {
    let lowercasedFilterText = filterText.lowercased()
    self = self.filter {
      let filterField = $0.filterText ?? $0.label
      return filterField.lowercased().hasPrefix(lowercasedFilterText)
    }
  }
}
