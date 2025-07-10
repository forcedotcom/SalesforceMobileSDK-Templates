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


import AgentforceService
import SalesforceSDKCore

/**
 * PlaygroundCredentials provides authentication credentials for Agentforce SDK integration.
 * 
 * This class implements the AgentforceAuthCredentialProviding protocol to supply
 * OAuth credentials from the Salesforce Mobile SDK's UserAccountManager.
 * 
 * ## Usage
 * The class is typically instantiated and passed to AgentforceClient during initialization:
 * ```swift
 * let credentialProvider = PlaygroundCredentials()
 * let agentforceClient = AgentforceClient(
 *     credentialProvider: credentialProvider,
 *     agentforceConfiguration: config
 * )
 * ```
 * 
 * ## Authentication Types Supported
 * - OAuth: Uses access token from Salesforce Mobile SDK
 * - OrgJWT: Alternative JWT-based authentication (commented example)
 * 
 * ## Dependencies
 * - Requires active Salesforce user session via UserAccountManager
 * - Access token must be valid and not expired
 */
class PlaygroundCredentials: AgentforceAuthCredentialProviding {
    
    /**
     * Retrieves current authentication credentials for Agentforce operations.
     * 
     * This method is called automatically by the Agentforce SDK when authentication
     * is required for API requests. It extracts credentials from the current
     * Salesforce user session managed by the Mobile SDK.
     * 
     * ## Implementation Details
     * - Fetches credentials from UserAccountManager.shared.currentUserAccount
     * - Returns OAuth credentials with access token, org ID, and user ID
     * - Provides empty strings as fallbacks if credentials are unavailable
     * 
     * ## Error Handling
     * The method provides graceful fallbacks with empty strings rather than
     * throwing errors. The Agentforce SDK will handle invalid credentials
     * appropriately by triggering re-authentication flows.
     * 
     * ## Alternative Authentication
     * For organizations using JWT-based authentication, uncomment and modify
     * the OrgJWT return statement with your JWT token.
     * 
     * - Returns: AgentforceAuthCredentials containing OAuth token information
     * 
     * ## Thread Safety
     * This method accesses UserAccountManager which is thread-safe, but should
     * typically be called from the main thread for consistency with UI operations.
     */
    func getAuthCredentials() -> AgentforceService.AgentforceAuthCredentials {
        // Retrieve current user credentials from Salesforce Mobile SDK
        let credentials = UserAccountManager.shared.currentUserAccount?.credentials
        
        // Return OAuth credentials with current session information
        return AgentforceAuthCredentials.OAuth(
            authToken: credentials?.accessToken ?? "",    // Current OAuth access token
            orgId: credentials?.organizationId ?? "",     // Salesforce organization ID  
            userId: credentials?.userId ?? ""             // Current user's Salesforce ID
        )
        
        // Alternative: JWT-based authentication for server-to-server scenarios
        // Uncomment and provide your JWT token if using this authentication method:
        // return AgentforceAuthCredentials.OrgJWT(orgJWT: "YOUR_ORG_JWT_TOKEN")
    }
}
