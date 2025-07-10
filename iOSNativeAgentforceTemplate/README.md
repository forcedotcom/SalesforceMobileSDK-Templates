# Agentforce iOS Demo Application

A comprehensive demo application showcasing the integration of Salesforce's Agentforce Mobile SDK for iOS. This template provides a complete starting point for building AI-powered mobile applications with Agentforce capabilities.

## Features

- **Agentforce Integration**: Full integration with Salesforce Agentforce Mobile SDK
- **Dual UI Modes**: Choose between out-of-the-box Agentforce UI or custom conversation interface
- **Voice Support**: Voice-enabled conversations with agents
- **Multi-Modal Input**: Support for text, voice, and file uploads (including PDF)
- **Salesforce Authentication**: OAuth integration with Salesforce
- **Configurable Settings**: Runtime configuration for agent IDs, URLs, and regions

## Requirements

- iOS 18.0+
- Xcode 15.0+
- CocoaPods
- Active Salesforce org with Agentforce enabled
- Valid Salesforce Connected App

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd AgentforceiOSTemplate
```

### 2. Configure Salesforce Connection

#### Option A: Use Existing Demo Configuration
The project comes with a demo configuration in `bootconfig.plist`. This includes:
- Pre-configured OAuth consumer key
- Redirect URI: `testsfdc:///mobilesdk/detect/oauth/done`
- OAuth scopes: `web`, `api`

#### Option B: Create Your Own Connected App
1. In Salesforce Setup, create a new Connected App
2. Enable OAuth settings with these scopes: `web`, `api`
3. Set the callback URL to: `testsfdc:///mobilesdk/detect/oauth/done`
4. Update `bootconfig.plist` with your consumer key

### 3. Configure Agent ID

In `Settings.swift`, update the default agent ID:

```swift
static let defaultAgentId = "YOUR_AGENT_ID_HERE"
```

### 4. Install Dependencies

```bash
pod install
```

### 5. Open Workspace

```bash
open iOSNativeAgentforceTemplate.xcworkspace
```

## Project Structure

```
iOSNativeAgentforceTemplate/
├── Classes/
│   ├── AgentforceLander.swift          # Main SwiftUI view with tabbed interface
│   ├── AgentforceLandingViewModel.swift # View model for main interface
│   ├── AppDelegate.swift               # Application lifecycle management
│   ├── InitialViewController.swift     # Initial view controller
│   ├── PlaygroundCredentials.swift    # Credential provider implementation
│   ├── PlaygroundNetwork.swift        # Network configuration
│   ├── SceneDelegate.swift            # Scene lifecycle management
│   └── Settings.swift                 # App settings and configuration UI
├── Supporting Files/
│   ├── Info.plist                     # App configuration
│   ├── PrivacyInfo.xcprivacy          # Privacy manifest
│   └── bootconfig.plist               # Salesforce OAuth configuration
└── iOSNativeAgentforceTemplate.entitlements
```

## Key Components

### AgentforceLander
The main SwiftUI view providing:
- Tabbed interface with Home and Settings
- Toggle between out-of-the-box Agentforce UI and custom conversation view
- Voice mode support
- Agent conversation initialization

### AgentforceClient Configuration
```swift
let config = AgentforceConfiguration(
    user: user,
    forceConfigEndpoint: PlaygroundNetwork.instanceURL,
    agentforceFeatureFlagSettings: AgentforceFeatureFlagSettings(
        enableMultiModalInput: true,
        enablePDFFileUpload: true,
        multiAgent: false
    ),
    salesforceNetwork: PlaygroundNetwork.init(),
    salesforceNavigation: nil
)
```

### Settings Management
- Runtime configuration for agent IDs and URLs
- Persistent settings storage via UserDefaults
- UI toggle for switching between UI modes

## Usage

### Basic Setup

1. Launch the app
2. Authenticate with your Salesforce org
3. Configure your agent ID in Settings (if needed)
4. Start a conversation from the Home tab

### Custom vs Out-of-the-Box UI

The app supports two interaction modes:

**Out-of-the-Box UI**: Uses Agentforce's built-in chat interface
- Full-screen modal presentation
- Complete feature set including voice, attachments, etc.
- Minimal custom code required

**Custom UI**: Allows building your own conversation interface
- Complete control over UI/UX
- Custom conversation handling
- Requires implementing ConversationView and ConversationViewModel

### Voice Features

Enable voice mode by setting `voiceMode = true` in the conversation configuration:

```swift
ConversationView(viewModel: ConversationViewModel(
    agentId: settings.agentId,
    voiceEnabled: true,
    onCancel: { ... }
))
```

## Configuration Options

### Agent Configuration
- **Agent ID**: Unique identifier for your Agentforce agent
- **SFAP URL**: Salesforce Agentforce Platform URL (for custom configurations)
- **Tenant ID**: Tenant identifier for multi-tenant setups
- **Target Region**: Geographic region for optimal performance

### Feature Flags
```swift
AgentforceFeatureFlagSettings(
    enableMultiModalInput: true,     // Enable voice and file inputs
    enablePDFFileUpload: true,       // Allow PDF file uploads
    multiAgent: false                // Single vs multi-agent conversations
)
```

## Customization

### Adding Custom Views
1. Implement custom conversation views in SwiftUI
2. Update the conversation routing in `AgentforceLander.swift`
3. Extend `ConversationViewModel` for custom business logic

### Network Configuration
Customize network settings in `PlaygroundNetwork.swift`:
- Base URLs
- Authentication handling
- Request/response processing

### Credential Management
Implement custom credential providers by conforming to `AgentforceAuthCredentialProviding`:
```swift
class CustomCredentialProvider: AgentforceAuthCredentialProviding {
    // Implement required methods
}
```

## Troubleshooting

### Common Issues

**Authentication Failures**:
- Verify your Connected App configuration
- Check OAuth scopes include `web` and `api`
- Ensure callback URL matches exactly

**Agent Not Found**:
- Verify agent ID is correct
- Ensure agent is published and active in your org
- Check user permissions for Agentforce access

**Build Errors**:
- Run `pod install` to ensure dependencies are current
- Clean build folder and rebuild
- Verify iOS deployment target is 18.0+

### Debug Tips

1. Enable verbose logging in Salesforce SDK
2. Check console logs for authentication and network issues
3. Verify agent configuration in Salesforce Setup
4. Test with different user accounts to isolate permission issues

## Dependencies

- **AgentforceSDK**: Core Agentforce functionality
- **AgentforceService**: Service layer for Agentforce operations
- **SalesforceSDKCore**: Core Salesforce Mobile SDK
- **SalesforceCache**: Caching functionality
- **MobileSync**: Data synchronization capabilities

## Support

For questions and support:
- Review the [Agentforce Mobile SDK Documentation](https://context7.com/salesforce/agentforcemobilesdk-ios/llms.txt)
- Check Salesforce Developer Documentation
- Submit issues to the Salesforce Mobile SDK GitHub repository