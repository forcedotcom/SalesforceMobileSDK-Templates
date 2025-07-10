/*
 Copyright (c) 2019-present, salesforce.com, inc. All rights reserved.
 
 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided
 with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written
 permission of salesforce.com, inc.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


import Foundation
import AgentforceSDK
import AgentforceService
import SalesforceUser
import SalesforceSDKCore
import Combine

/// Enum representing who sent a message in the conversation
enum MessageSender {
    case user
    case agent
}

/// Enum representing different types of messages in the conversation
enum MessageType {
    case progressIndicator  // Loading/thinking indicators
    case inform             // Complete informational messages
    case textChunk          // Streaming text chunks
    case userInput          // User-entered messages
}

/// Model representing a single chat message
struct ChatMessage: Identifiable, Hashable {
    /// Unique identifier for the message
    let id = UUID()
    /// Who sent this message (user or agent)
    let sender: MessageSender
    /// The text content of the message
    var content: String
    /// Flag indicating if content was recently updated (for streaming)
    var contentUpdated = false
    /// Type of message (affects display and behavior)
    let messageType: MessageType
    /// Whether the message has been processed/sent
    var isProcessed: Bool = true
}

/// Enum for managing keyboard focus states
enum FocusedField {
    case chatInput  // Chat input text field
}


/// View model managing conversation state and Agentforce service interactions
@Observable
class ConversationViewModel {
    /// Array of all chat messages in the conversation
    var messages: [ChatMessage] = []
    /// Whether currently establishing connection to agent
    var connectingToAgent = false
    /// Current keyboard focus state
    var focusedField: FocusedField?
    /// Service for communicating with Agentforce
    let agentforceService: AgentforceServicing
    /// Current session identifier for the conversation
    var currentSessionID: String?
    /// Publisher for receiving real-time events from Agentforce
    var eventPublisher: AnyCancellable?
    /// Callback executed when user cancels/closes conversation
    let onCancel: (() -> ())?
    /// Most recent event received from Agentforce
    var lastPublishedEvent: AgentforceEvent?
    /// Timer for handling input completion delays
    private var inputFinishedTimer: Timer?

    /// Initialize conversation view model with agent configuration
    /// - Parameters:
    ///   - agentId: Unique identifier for the Agentforce agent
    ///   - voiceEnabled: Whether voice capabilities are enabled
    ///   - onCancel: Optional callback for when conversation is cancelled
    init(agentId: String, voiceEnabled: Bool, onCancel: (() -> ())? = nil) {
        self.onCancel = onCancel
        // Set up Agentforce service with playground credentials
        let serviceProvider = AgentforceServiceProvider(network: PlaygroundNetwork(), credentialProvider: PlaygroundCredentials(), instrumentationHandler: nil, logger: nil)
        agentforceService = serviceProvider.agentforceServiceFor(agentId: agentId)
        startSession()
    }
    
    /// Initiates a new conversation session with the Agentforce agent
    func startSession() {
        connectingToAgent = true
        Task {
            do {
                // Start session with text streaming capabilities
                let response = try await agentforceService.startSession(instanceURL: PlaygroundNetwork.instanceURL, streamingCapabilities: [.Text])
                addStartSessionResponse(response)
                print(response)
            } catch {
                print(error)
            }
        }
    }
    
    /// Processes the response from starting a new session
    /// - Parameter response: The session start response containing session ID and initial messages
    func addStartSessionResponse(_ response: StartSessionResponse) {
        currentSessionID = response.sessionId
        
        // Update UI on main thread
        DispatchQueue.main.async { [weak self] in
            self?.connectingToAgent = false
            // Process any initial messages from the agent
            if let messages = response.messages {
                for message in messages {
                    self?.processMessage(message)
                }
            }
        }
       
        // Set up event publisher to receive real-time updates
        self.eventPublisher = agentforceService.eventPublisher
            .receive(on: RunLoop.main)
            .sink { error in
                print(error)
            } receiveValue: { [weak self] event in
                self?.processEvent(event)
            }
    }
    
    /// Processes incoming events from the Agentforce service
    /// - Parameter event: The event containing message data
    func processEvent(_ event: AgentforceEvent) {
        lastPublishedEvent = event
        processMessage(event.message)
    }
    
    /// Processes different types of messages from Agentforce
    /// - Parameter messsage: The abstract response message to process
    func processMessage(_ messsage: AbstractResponseMessage) {
        switch messsage {
        case .ProgressIndicator(let message):
            // Show loading/thinking indicators
            addAgentMessage(message.message, type: .progressIndicator)
            break
        case .InformMessage(let message):
            // Complete informational messages
            addAgentMessage(message.message, type: .inform)
            break
        case .TextChunk(let message):
            // Streaming text chunks for real-time response
            addAgentMessage(message.message, type: .textChunk)
            break
        case .EndOfTurn(_):
            // End of agent's response turn
            break
        case .Inquire(_), .Confirm(_),  .Failure(_),  .Escalate(_), .SessionEnded(_), .Error(_):
            print("Message type ignored: \(messsage)")
        case .LightningChunk(_):
            print("Message type ignored: \(messsage)")
        case .ValidationFailureChunk(_):
            print("Message type ignored: \(messsage)")
        case .CitationChunk(_):
            print("Message type ignored: \(messsage)")
        @unknown default:
            print("Message type ignored: \(messsage)")
        }
    }
    
    /// Adds a new message from the agent to the conversation
    /// - Parameters:
    ///   - message: The message content
    ///   - type: The type of message (affects display behavior)
    func addAgentMessage(_ message: String, type: MessageType) {
        // Remove any existing progress indicator when new content arrives
        if messages.last?.messageType == .progressIndicator {
            messages.removeLast()
        }
        
        // Handle streaming text chunks by appending to existing message
        if !messages.isEmpty && messages[messages.count-1].messageType == .textChunk {
            if type == .textChunk {
                // Append new chunk to existing streaming message
                messages[messages.count-1].content.append(message)
                messages[messages.count-1].contentUpdated = true
            } else if type == .inform {
                // Skip inform messages that follow text chunks to avoid duplication
                // TODO: Investigate impact on voice functionality
                // messages[messages.count-1].content = message

                print("Ignoring inform message: \(message)")
                return
            }

        } else { 
            // Add new complete message
            messages.append(ChatMessage(sender: .agent, content: message, messageType: type))
        }
    }
    
    /// Creates a new user message and adds it to the conversation
    /// - Parameter message: The user's message content
    /// - Returns: The created ChatMessage
    @discardableResult
    func createUserMessage(_ message: String) -> ChatMessage {
        let message = ChatMessage(sender: .user, content: message, messageType: .userInput, isProcessed: false)
        messages.append(message)
        return message
    }
    
    /// Sends a user message to the Agentforce service
    /// - Parameter message: The ChatMessage to send
    func sendUserMessage(_ message: ChatMessage) {
        let utterance = AgentforceUtterance(utterance: message.content, attachment: nil)
        guard let currentSessionID else {
            print("No session ID found, cannot send message")
            return
        }
        
        // Show progress indicator while processing request
        DispatchQueue.main.async { [weak self] in
            self?.messages.append(ChatMessage(sender: .agent, content: "Analyzing your request", messageType: .progressIndicator))
        }
        
        // Send message asynchronously
        Task {
            do {
                try await agentforceService.sendMessage(utterance, sessionId: currentSessionID)
            } catch {
                print(error)
            }
        }
    }
    
    /// Closes the conversation and cleans up resources
    func close() {
        eventPublisher?.cancel()
        agentforceService.cancel()
        onCancel?()
    }
    
    /// Called when the view appears - sets focus to chat input
    func onAppear() {
        focusedField = .chatInput
    }
    
    /// Called when the view disappears - cleans up the conversation
    func onDisappear() {
        close()
    }
    
    /// Handles user input by creating and sending a message
    /// - Parameter input: The user's input text
    func userAddedInput(_ input: String) {
        let message = createUserMessage(input)
        sendUserMessage(message)
    }
}
