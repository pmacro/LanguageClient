//
//  LanguageClient.swift
//  Editor
//
//  Created by pmacro on 05/02/2019.
//

import Foundation
import PromiseKit

public protocol LanguageClientNotificationDelegate {
  func receive(diagnostics: [Diagnostic])
  func receive(message: LogMessage) -> Bool
}

public typealias DocumentURI = String

///
/// A client that connects to a language server, sending and receiving messages according
/// to the Language Server Protocol and JSON RPC.
///
public class LanguageClient {
  
  /// LSP notification types.
  enum Notification: String {
    case diagnostic = "textDocument/publishDiagnostics"
    case logMessage = "window/logMessage"
  }
  
  /// The underlying JSON RPC channel.
  public let rpc = JSONRPCChannel()
  
  /// The server's reported capabilities.  This property will be populated
  /// post client initialisation.
  public var capabilities: ServerCapabilities?
  
  /// Diagnostics by file URI.
  var allDiagnostics = [DocumentURI: [Diagnostic]]()
  
  /// Delegates for each known document.
  private var delegates = [(DocumentURI, LanguageClientNotificationDelegate)]()
  
  /// The source path of the content.
  var sourcePath: String?

  /// Environment variables to pass to the language server process.
  public var environmentVariables: [String: String] = [:]
  
  public init() {
    rpc.notificationHandler = { [weak self] (method, data) in
      self?.handleNotification(name: method, data: data)
    }
  }
  
  ///
  /// Handles a notification coming from the language server.
  ///
  public func handleNotification(name: String, data: Data) {
    switch Notification(rawValue: name) {
    case .diagnostic?:
      do {
        let diagnostics = try JSONDecoder().decode(Diagnostics.self, from: data)
        allDiagnostics[diagnostics.params.uri] = diagnostics.params.diagnostics
        delegates.filter { $0.0 == diagnostics.params.uri }
          .forEach { $0.1.receive(diagnostics: diagnostics.params.diagnostics) }
      } catch let error {
        print("error: \(error)")
      }
    case .logMessage?:
      do {
        let message = try JSONDecoder().decode(LogMessage.self, from: data)
        for delegate in delegates {
          if delegate.1.receive(message: message) {
            // If this delegate handled the message
            break
          }
        }
      } catch let error {
        print("error: \(error)")
      }
    default:
      print("Unsupported notification type: \(name)")
      break
    }
  }
  
  ///
  /// Registers a delegate for notifications about a particular document.
  ///
  public func register(_ delegate: LanguageClientNotificationDelegate,
                       forURI uri: DocumentURI) {
    delegates.append((uri, delegate))
  }
  
  ///
  /// Starts the language server at `serverPath` and initializes it for the content in
  /// `sourcePath`.
  ///
  public func startServer(atPath serverPath: String, sourcePath: String)
    -> Promise<InitializeResult> {
    rpc.environmentVariables = environmentVariables
    rpc.startChannel(atPath: serverPath)
    self.sourcePath = sourcePath
    return initialize(sourcePath: sourcePath)
  }
  
  ///
  /// Calls `initialize` on the language server for the content in `sourcePath`.
  ///
  func initialize(sourcePath: String) -> Promise<InitializeResult> {
    let params = InitializeParams(processId: ProcessInfo.processInfo.processIdentifier,
                                  rootPath: sourcePath,
                                  capabilities: ClientCapabilities())
    let initialize = InitializeRequest(params: params)
    
    let promise = send(message: initialize, responseType: InitializeResult.self)
    
    _ = promise.done { [weak self] result in
      self?.capabilities = result.capabilities
    }
      
    return promise
  }  
}

extension LanguageClient: JSONRPCMessageSender {
  public func send<T, R>(message: T, responseType: R.Type) -> Promise<R> where T : JSONRPCMessage, R : JSONRPCResult {
    return rpc.send(message: message, responseType: responseType)
  }
  
  public func send<T>(notification: T) where T : JSONRPCMessage {
    rpc.send(notification: notification)
  }
}
