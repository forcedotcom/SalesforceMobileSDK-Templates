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
import AgentforceSDK
import SalesforceUser

/// Main SwiftUI view providing tabbed interface for Agentforce demo application
/// Supports both out-of-the-box Agentforce UI and custom conversation interface
struct AgentforceLander: View {
    @Bindable var viewModel: AgentforceLandingViewModel
    @Bindable var settings: Settings
    @State var userInput: String = ""
    @State var voiceMode = false
    
    /// Agentforce client instance for managing conversations
    let agentforceClient: AgentforceClient
    
    /// Initialize the main view with required dependencies
    /// Sets up AgentforceClient with current user credentials and feature flags
    init(viewModel: AgentforceLandingViewModel, settings: Settings) {
        self.viewModel = viewModel
        self.settings = settings
        
        // Get current user credentials from Salesforce SDK
        let credentials = UserAccountManager.shared.currentUserAccount!.credentials
        let user = User(userId: credentials.userId!, org: Org(id:credentials.organizationId!), username: "", displayName: "")
        
        // Configure Agentforce with feature flags
        let config = AgentforceConfiguration(
            user: user,
            forceConfigEndpoint: PlaygroundNetwork.instanceURL,
            agentforceFeatureFlagSettings: AgentforceFeatureFlagSettings(
                enableMultiModalInput: true,  // Enable voice and file inputs
                enablePDFFileUpload: true,    // Allow PDF attachments
                multiAgent: false             // Single agent conversations
            ),
            salesforceNetwork: PlaygroundNetwork.init(),
            salesforceNavigation: nil
        )
        
        // Initialize Agentforce client with credentials and configuration
        self.agentforceClient = AgentforceClient(credentialProvider: PlaygroundCredentials(), agentforceConfiguration: config)
        
        // Customize navigation bar appearance
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
    }
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                NavigationStack {
                    VStack(alignment: .center, spacing: 0) {
                        if viewModel.showConversation {
                            // Display custom conversation interface
                            ConversationView(viewModel: ConversationViewModel(
                                agentId: settings.agentId, 
                                voiceEnabled: voiceMode, 
                                onCancel: {
                                    // Hide conversation view with animation when user cancels
                                    withAnimation {
                                        viewModel.showConversation = false
                                    }
                                }))
                            .transition(.opacity)
                            
                        } else {
                            // Display landing screen with placeholder UI and input field
                            Text("Your UI Here").font(.title).padding()
                                .bold()
                                .foregroundStyle(.black)
                                .padding(.top, 200)
                            
                            Spacer()
                            HStack {
                                // Input field that triggers conversation based on settings
                                TextInputField(userInput: $userInput, placeholderText: "Talk to an agent", onSubmission: nil)
                                    .disabled(true)
                                    .onTapGesture {
                                        // Route to appropriate UI based on settings preference
                                        if settings.outOfTheBoxUI {
                                            viewModel.showAgentforceUI = true
                                        } else {
                                            viewModel.showConversation = true
                                        }
                                    }
                            }.padding()
                        }
                        
                    }
                    .background {
                        // Background image that fills the entire screen
                        GeometryReader { geometry in
                            Image("background")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(alignment: .center)
                                .edgesIgnoringSafeArea(.all)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .navigationViewStyle(StackNavigationViewStyle())
                    .toolbarBackground(.visible, for: .tabBar)
                }
                .fullScreenCover(isPresented: $viewModel.showAgentforceUI) {
                    // Present out-of-the-box Agentforce UI as full-screen modal
                    AgentforceContainer
                }
            }
            
            Tab("Settings", systemImage: "gear") {
                SettingsView()
            }
        }.environment(settings)
    }
    
    /// Container view for out-of-the-box Agentforce UI
    var AgentforceContainer: some View {
        openSession()
    }
    
    /// Refresh the current user session with Salesforce
    private func refreshSession() {
        if let credentials = UserAccountManager.shared.currentUserAccount?.credentials {
            let _ = UserAccountManager.shared.refresh(credentials: credentials) { _ in
            }
        }
    }
    
    /// Create and configure Agentforce chat view
    /// - Parameter initialUtterance: Optional initial message to start conversation
    /// - Returns: Configured chat view or empty view if creation fails
    @MainActor @ViewBuilder
    private func openSession(initialUtterance: String? = nil) -> some View {
        let conversation = agentforceClient.startAgentforceConversation(forAgentId: Settings.defaultAgentId)
        if let chatView = try? agentforceClient.createAgentforceChatView(
            conversation: conversation,
            delegate: nil,
            onContainerClose:{
                viewModel.showAgentforceUI = false
            }) {
            chatView
        } else {
            EmptyView()
        }
    }
}

/// Data model for button configuration in button groups
struct ButtonContents: Identifiable {
    let id = UUID()
    let image: String
    let action: () -> Void
}

/// Reusable capsule-shaped button group component
/// Creates a horizontal group of buttons with dividers
struct CapsuleButtonGroup: View {
    let buttons: [ButtonContents]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(buttons) { button in
                Button {
                    button.action()
                } label: {
                    Image(systemName: button.image)
                }
                if button.id != buttons.last?.id {
                    Divider()
                        .frame(width: 1, height: 20)
                        .padding(.horizontal)
                }
            }
        }
        .font(.title3)
        .foregroundStyle(.white)
        .padding()
        .background {
            Capsule()
                .fill(Color(red: 102/255, green: 162/255, blue: 170/255))
                .frame(height: 50)
        }
    }
}

#Preview {
    let viewModel = AgentforceLandingViewModel()
    viewModel.showConversation = false
    return AgentforceLander(viewModel: viewModel, settings: Settings())
}
