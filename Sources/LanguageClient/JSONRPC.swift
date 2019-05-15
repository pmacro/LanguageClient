//
//  JSONRPC.swift
//  Editor
//
//  Created by pmacro on 05/02/2019.
//

import Foundation
import PromiseKit

public enum JSONRPCError: Error {
  case unknown
  case messageDecoding
  case processNotRunning
}

///
/// A JSONRPC connection that can send and receive messages over the JSON RPC protocol.
///
public class JSONRPCChannel: JSONRPCMessageSender {
  
  static let HeaderTerminator = "\r\n\r\n"
  static let HeaderTerminatorData: [UInt8] = [13, 10, 13, 10]

  /// A queue for processing messages in the background.
  let backgroundQueue = DispatchQueue(label: "JSONRPC-Background")
  
  /// The spawned server process.
  var process = Process()
  
  /// The pipe for writing data to the server.
  var processInput = Pipe()
  
  /// The pip for reading data from the server.
  var processOutput = Pipe()
  
  /// The path of the server executable.
  var currentChannelPath: String?
  
  /// A record of pending results, i.e. message that have been sent but for which we have
  /// not yet received a result.
  var pendingResults = [String: JSONRPCPendingResult]()

  /// Environment variables to be added to the child JSON RPC process.
  public var environmentVariables: [String: String] = [:]  

  /// Is the underlying server process running.
  public var isRunning: Bool {
    return process.isRunning
  }
  
  /// An ID message counter.
  var idCounter = 0

  /// An ID message generator.
  var nextId: String {
    idCounter += 1
    return "\(idCounter)"
  }
  
  /// The handler for notifications recieved from the channel.  The first argument is
  /// the method name, and the second is the notification data.
  typealias NotificationHandler = (String, Data) -> Void
  var notificationHandler: NotificationHandler?
  
  let responseQueue: DispatchQueue = DispatchQueue(label: "jsonrpc-queue",
                                                  qos: .userInitiated)
  
  let writeQueue: DispatchQueue = DispatchQueue(label: "jsonrpc-write-queue",
                                                   qos: .userInitiated)

  var responseIO: DispatchIO!
  var writeIO: DispatchIO!
  var responseBuffer = [UInt8]()
  
  public init() {

  }
  
  ///
  /// Starts a channel using an executable at the specified path, then readies it for
  /// reading and writing.
  ///
  public func startChannel(atPath path: String) {
    self.currentChannelPath = path
    process = Process()
    
    if #available(OSX 10.13, *) {
      self.process.executableURL = URL(fileURLWithPath: path)
    } else {
      self.process.launchPath = path
    }
    
    // Add in any configured environment variables.
    var env = ProcessInfo.processInfo.environment

    for (key, value) in environmentVariables {
      env[key] = value
    }

    self.process.environment = env
    
    self.processInput = Pipe()
    self.processOutput = Pipe()
      
    self.process.standardInput = self.processInput
    self.process.standardOutput = self.processOutput
    
    responseIO = DispatchIO(type: .stream,
                            fileDescriptor: processOutput.fileHandleForReading.fileDescriptor,
                            queue: responseQueue) { (error: Int32) in
      if error != 0 {
        print("IO Error in JSONRPC")
      }
    }
    
    responseIO.setLimit(lowWater: 1)
    responseIO.setLimit(highWater: Int.max)

    writeIO = DispatchIO(type: .stream,
                         fileDescriptor: processInput.fileHandleForWriting.fileDescriptor,
                         queue: writeQueue) { (error: Int32) in
      if error != 0 {
        print("IO error in JSONRPC")
      }
    }
    
    writeIO.setLimit(lowWater: 1)
    writeIO.setLimit(highWater: Int.max)
    
    responseIO.read(offset: 0, length: Int.max, queue: responseQueue) {
      done, data, errorCode in
      
      guard errorCode == 0 else {
        print("IO error \(errorCode) in JSONRPC")
        
        if done { _ = self.shutdownChannel() }
        return
      }
      
      if done {
        _ = self.shutdownChannel()
        return
      }

      guard let data = data, !data.isEmpty else {
        return
      }

      self.responseBuffer.append(contentsOf: data)
      self.readResponse()
    }
    
    // Launch the process in the background.
    backgroundQueue.async { [weak self] in
      guard let `self` = self else { return }
      self.process.launch()
    }
  }
  
  ///
  /// Shutdown the channel and clean up all resources.
  ///
  public func shutdownChannel() -> Promise<Bool> {
    return Promise { resolver in
      backgroundQueue.async { [weak self] in
        self?.process.terminate()
        self?.processInput.fileHandleForWriting.closeFile()
        self?.processOutput.fileHandleForReading.closeFile()
        resolver.fulfill(true)
        self?.responseIO.close(flags: .stop)
        self?.writeIO.close(flags: .stop)
      }
    }
  }

  ///
  /// Sends a message to the current channel, then waits for the expected response, returning
  /// it, or an error, in the future.
  ///
  public func send<T: JSONRPCMessage, R: JSONRPCResult>(message: T,
                                                 responseType: R.Type) -> Promise<R> {
    return Promise<R>() { resolver in
      backgroundQueue.async { [weak self] in
        guard let `self` = self else { return }
        let messageId = self.nextId
      
        var msg = message
        msg.id = messageId

        guard let messageData = self.prepare(message: msg) else {
          resolver.reject(JSONRPCError.unknown)
          return
        }
        
        self.write(data: messageData)

        let resultQueueEntry: JSONRPCPendingResult = { [weak self] data in
          self?.sendResultMessage(data: data, resolver: resolver)
        }
        
        self.pendingResults[messageId] = resultQueueEntry
      }
    }
  }
  
  ///
  /// Sends a notification message to the current channel.
  ///
  public func send<T: JSONRPCMessage>(notification: T) {
    backgroundQueue.async { [weak self] in
      guard let `self` = self,
        let messageData = self.prepare(message: notification) else {
        return
      }
      
      if !self.process.isRunning, let path = self.currentChannelPath {
        self.startChannel(atPath: path)
      }
      
      if self.process.isRunning {
        self.write(data: messageData)
      }
    }
  }
  
  ///
  /// Writes data to the channel.
  ///
  func write(data: Data) {
    guard !data.isEmpty else { return }
    
    var dispatchData = DispatchData.empty
    data.withUnsafeBytes { dispatchData.append($0) }
    
    writeIO.write(offset: 0,
                  data: dispatchData,
                  queue: writeQueue) { [weak self] done, _, errorCode in
      if errorCode != 0 {
        print("IO error sending message \(errorCode)")
        if done {
          _ = self?.shutdownChannel()
        }
      }
    }

  }
  
  ///
  /// Prepare a message for sending by adding a header and converting it into a Data object.
  ///
  func prepare<T: JSONRPCMessage>(message: T) -> Data? {
    var msg = message
    msg.jsonrpc = "2.0"
    
    guard let jsonData = try? JSONEncoder().encode(msg) else {
      print("Failed to construct JSON RPC message.")
      return nil
    }
    
    let string = "Content-Length: \(jsonData.count)\(JSONRPCChannel.HeaderTerminator)"
    let headerData = string.data(using: .ascii)!
    return headerData + jsonData
  }
  
  ///
  /// Reads a response from the server.
  ///
  func readResponse() {
    if responseBuffer.isEmpty {
      return
    }
    
    var messageHeader: JSONRPCHeader?
    var startIndex = responseBuffer.startIndex
    
    // If we have a header, read it and point startIndex to the first byte after it.
    if let index = responseBuffer.firstRange(of: JSONRPCChannel.HeaderTerminatorData) {
      let headerData = responseBuffer[startIndex..<index.lowerBound]
      
      if let headerString = String(bytes: headerData, encoding: .ascii) {
        messageHeader = JSONRPCHeader(from: headerString)
      }

      startIndex = index.upperBound
    }
    
    guard let header = messageHeader else {
      print("JSONRPC Error: no header found.")
      return
    }
    
    guard header.contentLength > 0 else { return }
    
    // Read the expected content length from the response buffer.
    let dataCount = responseBuffer.distance(from: startIndex,
                                            to: responseBuffer.endIndex)
    let readData = responseBuffer[startIndex...]
    
    // We've read the content length exactly, so we're done.
    if dataCount == header.contentLength {
      processResponse(Array(readData))
      responseBuffer = []
    }
    // We read more content than is in this single message, so process the part we need
    // then call readResponse to handle the excess.
    else if dataCount > header.contentLength {
      let messageEnd = startIndex + header.contentLength
      let messageData = responseBuffer[startIndex..<messageEnd]
      processResponse(Array(messageData))
      responseBuffer = Array(responseBuffer[messageEnd...])
      readResponse()
    }
  }
  
  ///
  /// Processes a response from the server, converting it to the expected response type
  /// and then padding it on.  This removes the message from the list of pending results.
  ///
  func processResponse(_ data: [UInt8]) {
    do {
      let dataObject = Data(data)
    let response = try JSONDecoder().decode(JSONRPCResultPeeker.self,
                                            from: dataObject)
      if let id = response.id {
        if let pendingResult = pendingResults[id] {
          DispatchQueue.main.async {
            pendingResult(dataObject)
          }
        }
        pendingResults.removeValue(forKey: id)
      }
      else if let method = response.method {
        DispatchQueue.main.async { [weak self] in
          self?.notificationHandler?(method, dataObject)
        }
      }
      else {
        print("Unknown message type.")
      }
    } catch let error {
      print(error)
    }
  }
  
  ///
  /// Sends a typed result message through the resolver.
  ///
  func sendResultMessage<T: JSONRPCResult>(data: Data,
                                           resolver: Resolver<T>) {
    
    do {
      let response = try JSONDecoder().decode(JSONRPCWrappedResult<T>.self,
                                              from: data)
      if let result = response.result {
        resolver.fulfill(result)
      } else {
        resolver.reject(JSONRPCError.unknown)
      }
    }
    catch let error {
      resolver.reject(error)
    }
  }
}
