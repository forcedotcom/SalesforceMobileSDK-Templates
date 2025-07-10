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
import SwiftUI

/**
 * AgentforceLandingViewModel manages the UI state for the main landing screen.
 * 
 * This view model follows the MVVM pattern and uses Swift's @Observable macro
 * for automatic UI updates when state changes. It coordinates between different
 * conversation UI modes in the Agentforce demo application.
 * 
 * ## State Management
 * The view model manages two primary UI states that determine which conversation
 * interface is displayed to the user:
 * 
 * - **Custom Conversation UI**: Managed by `showConversation`
 * - **Out-of-the-Box Agentforce UI**: Managed by `showAgentforceUI`
 * 
 * ## Usage Pattern
 * Typically instantiated in the main view and passed as a binding:
 * ```swift
 * let viewModel = AgentforceLandingViewModel()
 * AgentforceLander(viewModel: viewModel, settings: settings)
 * ```
 * 
 * ## UI Flow
 * 1. User taps input field on landing screen
 * 2. Settings determine which UI mode to activate
 * 3. Appropriate boolean flag is set to true
 * 4. SwiftUI reacts to state change and presents the interface
 * 5. Conversation completion sets flag back to false
 * 
 * ## Thread Safety
 * All property modifications should occur on the main thread since this
 * view model directly drives UI state changes.
 */
@Observable class AgentforceLandingViewModel {
    
    /**
     * Controls the visibility of the custom conversation interface.
     * 
     * When set to `true`, the main view displays a custom-built conversation
     * interface that provides full control over the chat experience. This mode
     * requires implementing custom UI components and conversation handling logic.
     * 
     * ## UI Behavior
     * - `true`: Shows custom ConversationView with fade-in animation
     * - `false`: Hides conversation view and returns to landing screen
     * 
     * ## Associated Components
     * - ConversationView: Custom SwiftUI conversation interface
     * - ConversationViewModel: Business logic for custom chat
     * 
     * ## State Transitions
     * - Set to `true` when user chooses custom UI mode
     * - Set to `false` when conversation is cancelled or completed
     * - Mutually exclusive with `showAgentforceUI`
     */
    var showConversation = false
    
    /**
     * Controls the visibility of the out-of-the-box Agentforce UI.
     * 
     * When set to `true`, the main view presents Agentforce's built-in chat
     * interface as a full-screen modal. This provides a complete chat experience
     * with minimal custom code required.
     * 
     * ## UI Behavior
     * - `true`: Presents full-screen Agentforce chat interface
     * - `false`: Dismisses modal and returns to landing screen
     * 
     * ## Associated Components
     * - AgentforceContainer: Wrapper view for Agentforce UI
     * - AgentforceChatView: SDK-provided chat interface
     * 
     * ## Features Included
     * - Voice input and output capabilities
     * - File attachment support (including PDF)
     * - Rich message formatting
     * - Agent typing indicators
     * - Message history and persistence
     * 
     * ## State Transitions
     * - Set to `true` when user chooses out-of-the-box UI mode
     * - Set to `false` when user closes the chat interface
     * - Mutually exclusive with `showConversation`
     */
    var showAgentforceUI = false
}
