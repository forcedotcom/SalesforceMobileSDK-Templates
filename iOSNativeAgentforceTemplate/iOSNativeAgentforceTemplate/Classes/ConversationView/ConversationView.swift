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

import SwiftUI
import SalesforceSDKCore
import Combine

/// A custom text input field component for user chat messages
struct TextInputField: View {
    /// Two-way binding to the text input value
    @Binding var userInput: String
    /// Placeholder text displayed when input is empty
    let placeholderText: String
    /// Callback executed when user submits the text
    let onSubmission: (() -> ())?

    var body: some View {
        HStack {
            TextField(placeholderText, text: $userInput)
                .onSubmit {
                    // Execute submission callback and clear input
                    onSubmission?()
                    userInput = ""
                }
                .padding()
                .background(Color(uiColor: UIColor.salesforceTableCellBackground))
                .cornerRadius(10)
                .multilineTextAlignment(.leading)
        }
    }
}

/// Main conversation view displaying chat messages and input field
struct ConversationView: View {
    /// View model managing conversation state and logic
    @State var viewModel: ConversationViewModel
    /// Current text input from the user
    @State private var userInput: String = ""
    /// Focus state for managing keyboard focus
    @FocusState private var focusedField: FocusedField?
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            // Scrollable message area with auto-scroll functionality
            ScrollViewReader { proxy in
                ScrollView {
                    VStack {
                        // Show connection status when establishing agent connection
                        if viewModel.connectingToAgent {
                            HStack(alignment: .center, spacing: 0) {
                                Text("Connecting to agent")
                                AnimatedEllipsis()
                            }
                            .font(.system(size: 16, weight: .regular)).italic()
                            .foregroundStyle(.white)
                        }
                        // Display all chat messages
                        ForEach(viewModel.messages) { message in
                            MessageCell(message: message)
                                .id(message.id)
                                .padding(.horizontal, 5)
                        }
                        // TODO: Consider implementing autoscroll behavior
                        // Spacer().frame(height: 100)
                    }
                    .padding(.top, 20) // Offset for gradient mask
                    .padding(.bottom, 50)
                }
               
                .scrollIndicators(.hidden)
                // Apply fade gradient mask at top and bottom edges
                .mask({
                    LinearGradient(stops: [Gradient.Stop(color: .clear, location: 0.0),
                                           Gradient.Stop(color: .black, location: 0.05),
                                           Gradient.Stop(color: .black, location: 0.9),
                                           Gradient.Stop(color: .clear, location: 1.0)],
                                   startPoint: .top,
                                   endPoint: .bottom)
                })
                // Handle automatic scrolling when new messages arrive
                .onReceive(Just(viewModel.messages)) { messages in
                    if let lastMessage = messages.last, lastMessage.contentUpdated {
                        // Avoid scrolling during token streaming to prevent jarring movement
                        return
                    }
                    
                    // Find the most recent user message to scroll to
                    let lastUserMessage = messages.last { message in
                        message.sender == .user
                    }
                    
                    // Animate scroll to the last user message
                    if let lastUserMessage {
                        withAnimation {
                            proxy.scrollTo(lastUserMessage.id, anchor: .top)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding([.horizontal, .top])
            }
            
            // User input area at bottom of screen
            HStack {
                TextInputField(userInput: $userInput, placeholderText: "Talk to an agent") {
                    // Send user input to view model
                    viewModel.userAddedInput(userInput)
                    userInput = ""
                }
                .focused($focusedField, equals: .chatInput)
            }.padding()
        }
        .background(.thinMaterial)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                // Close/cancel button in navigation bar
                Button(action: {
                    viewModel.onCancel?()
                }, label: {
                    Image(systemName: "xmark").foregroundStyle(.white)
                })
            }
        }
        .navigationBarTitle("Chatting with Agentforce", displayMode: .large)
        .onDisappear {
            viewModel.onDisappear()
        }
        .onAppear() {
            viewModel.onAppear()
            
            // Configure navigation bar appearance with white text
            // TODO: Consider moving this to app-wide configuration
            let color = Color.white
            let coloredAppearance = UINavigationBarAppearance()
            coloredAppearance.titleTextAttributes = [.foregroundColor: UIColor(color)]
            coloredAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(color)]
            coloredAppearance.configureWithTransparentBackground()
            UINavigationBar.appearance().standardAppearance = coloredAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
            UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).adjustsFontSizeToFitWidth = true
        }
        // Synchronize focus state between view and view model
        .onChange(of: self.viewModel.focusedField) { _, newValue in
          self.focusedField = newValue
        }
        .onChange(of: self.focusedField) { _, newValue in
          self.viewModel.focusedField =  newValue
        }
    }
}

/// SwiftUI preview with sample conversation data
#Preview {
    // Create test view model with sample messages
    let model = ConversationViewModel(agentId: "test", voiceEnabled: false)
    model.addAgentMessage("You can contact us at <sample>.", type: .inform)
    model.addAgentMessage(String(repeating: "This is a longer message to take up more space.", count: 10), type: .inform)
    model.addAgentMessage(String(repeating: "This is a longer message to take up more space.", count: 10), type: .inform)
    model.addAgentMessage(String(repeating: "This is a longer message to take up more space.", count: 10), type: .inform)
    return ConversationView(viewModel: model)
}
