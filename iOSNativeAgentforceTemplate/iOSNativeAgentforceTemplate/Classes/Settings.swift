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

/// Settings class for managing app configuration and user preferences
/// Provides persistent storage for agent configuration and UI preferences
@Observable class Settings {
    // UserDefaults keys for persistent storage
    static let agentKey = "agentId"
    static let urlKey = "sfapURL"
    static let tenantIdKey = "tenantId"
    static let targetRegionKey = "targetRegion"
    static let defaultAgentId = <#T##String#>
   
    /// Toggle between out-of-the-box Agentforce UI and custom conversation interface
    var outOfTheBoxUI: Bool = true
    
    /// Unique identifier for the Agentforce agent
    var agentId: String
    
    /// Salesforce Agentforce Platform URL for custom configurations
    var sfapURL: String
    
    /// Tenant identifier for multi-tenant setups
    var tenantId: String
    
    /// Geographic region for optimal performance
    var targetRegion: String
    
    /// Combine cancellables for managing subscriptions
    var cancellables: Set<AnyCancellable> = []
    
    /// Initialize settings with values from UserDefaults or default values
    init() {
        agentId = UserDefaults.standard.object(forKey: Settings.agentKey) as? String ?? Settings.defaultAgentId
        sfapURL = UserDefaults.standard.object(forKey: Settings.urlKey) as? String ?? ""
        tenantId = UserDefaults.standard.object(forKey: Settings.tenantIdKey) as? String ?? ""
        targetRegion = UserDefaults.standard.object(forKey: Settings.targetRegionKey) as? String ?? ""
        
        // Save settings to UserDefaults when app terminates
        NotificationCenter.default
            .publisher(for: UIApplication.willTerminateNotification)
            .sink { [weak self] _ in
                UserDefaults.standard.set(self?.agentId, forKey: Settings.agentKey)
                UserDefaults.standard.set(self?.sfapURL, forKey: Settings.urlKey)
                UserDefaults.standard.set(self?.tenantId, forKey: Settings.tenantIdKey)
                UserDefaults.standard.set(self?.targetRegion, forKey: Settings.targetRegionKey)
            }
            .store(in: &cancellables)
    }
    
}

/// SwiftUI view for configuring app settings
/// Provides interface for agent configuration and UI preferences
struct SettingsView: View {
    @Environment(Settings.self) var settings

    var body: some View {
        List {
            // Agent configuration section
            Section(header: Text("Agent Configuration")) {
                @Bindable var settings = settings
                
                // Agent ID field - always visible and required
                LabeledContent("Agent ID") {
                    TextField("Agent ID", text: $settings.agentId, prompt: nil)
                }
                
                // Advanced configuration fields - only shown for custom Connected Apps
                // Hidden for default SfdcMobile consumer key to simplify demo setup
                if let consumerKey = SalesforceManager.shared.bootConfig?.remoteAccessConsumerKey,
                   !consumerKey.contains("SfdcMobile") {
                    
                    LabeledContent("SFAP URL") {
                        TextField("sfapURL", text: $settings.sfapURL, prompt: nil)
                    }
                    LabeledContent("Tenant Id") {
                        TextField("tenantId", text: $settings.tenantId, prompt: nil)
                    }
                    LabeledContent("Target Region") {
                        TextField("targetRegion", text: $settings.targetRegion, prompt: nil)
                    }
                }
            }
            
            // UI preference section
            Section {
                @Bindable var settings = settings
                // Toggle between Agentforce SDK UI and custom conversation interface
                Toggle("Use Out of the Box UI", isOn: $settings.outOfTheBoxUI)
            }
            
            // Account management section
            Section {
                Button {
                    // Trigger logout flow via Salesforce SDK
                    UserAccountManager.shared.logout()
                } label: {
                    Text("Log out").foregroundStyle(.red)
                }
            }
        }
    }
}
