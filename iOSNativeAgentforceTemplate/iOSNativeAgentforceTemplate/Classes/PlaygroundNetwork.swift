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
import SalesforceNetwork

/**
 * Custom network errors for PlaygroundNetwork operations.
 * 
 * These errors provide specific feedback when network operations fail
 * due to missing configuration or invalid state.
 */
enum NetworkError: Error {
    /// The request URL is malformed or missing
    case invalidURL
    /// No authenticated user session is available
    case noCurrentUser
    /// Salesforce instance URL is not available
    case noInstanceURL
    /// Organization ID is missing from user credentials
    case noOrganizationId
}

/**
 * PlaygroundNetwork provides custom networking implementation for Agentforce SDK.
 * 
 * This class bridges the Agentforce SDK's network requirements with Salesforce Mobile SDK's
 * RestClient, enabling authenticated API calls to both Salesforce and external Einstein services.
 * 
 * ## Key Features
 * - Automatic authentication via Salesforce Mobile SDK
 * - Support for both internal Salesforce APIs and external Einstein endpoints
 * - Header preservation from original requests
 * - JSON content type handling
 * - Error handling for common network scenarios
 * 
 * ## Usage
 * Typically instantiated and passed to AgentforceConfiguration:
 * ```swift
 * let network = PlaygroundNetwork()
 * let config = AgentforceConfiguration(
 *     // other parameters...
 *     salesforceNetwork: network
 * )
 * ```
 * 
 * ## Supported URL Patterns
 * 1. **External Einstein APIs**: Full URLs with host (e.g., https://api.salesforce.com/einstein/...)
 * 2. **Internal Salesforce APIs**: Relative paths (e.g., /services/data/v62.0/...)
 */
public class PlaygroundNetwork: SalesforceNetwork.Network {
    
    /**
     * Provides the current Salesforce instance URL for API requests.
     * 
     * This computed property extracts the API URL from the current user's credentials
     * managed by the Salesforce Mobile SDK. The URL is used as the base for relative
     * API requests and for Agentforce configuration.
     * 
     * ## Implementation Details
     * - Accesses UserAccountManager.shared.currentUserAccount
     * - Extracts apiUrl from current user credentials
     * - Converts URL to absolute string format
     * 
     * ## Error Handling
     * This property force-unwraps the current user and API URL, assuming that
     * authentication has been completed before this property is accessed.
     * In production code, consider adding proper error handling.
     * 
     * - Returns: String representation of the Salesforce instance API URL
     * 
     * ## Thread Safety
     * Accesses UserAccountManager which is thread-safe, but typically called
     * from main thread during configuration.
     */
    static public var instanceURL: String {
        let currentUser = UserAccountManager.shared.currentUserAccount!.credentials
        let url = currentUser.apiUrl!.absoluteString
        return url
    }
    
    /**
     * Executes network requests using Salesforce Mobile SDK's RestClient.
     * 
     * This method is the core of the network implementation, handling all HTTP requests
     * from the Agentforce SDK by translating them into RestRequest objects that can
     * be processed by the Salesforce Mobile SDK.
     * 
     * ## Request Processing Flow
     * 1. Validates the incoming request URL
     * 2. Determines if request is for external Einstein API or internal Salesforce API
     * 3. Creates appropriate RestRequest configuration
     * 4. Transfers headers and body data
     * 5. Executes request via RestClient.shared
     * 6. Returns response data and URL response
     * 
     * ## URL Handling Strategy
     * - **Full URLs with host**: Treated as external Einstein API calls
     *   - Example: "https://api.salesforce.com/einstein/ai-agent/v1/agents/{id}/sessions"
     *   - Uses customUrlRequest with explicit base URL and path
     *   - Requires authentication via requiresAuthentication = true
     * 
     * - **Relative paths**: Treated as internal Salesforce API calls
     *   - Example: "/services/data/v62.0/connect/conversation-runtime-proxy"
     *   - Uses standard RestRequest constructor
     *   - Authentication handled automatically by RestClient
     * 
     * ## Authentication
     * All requests are authenticated using the current user's OAuth token
     * managed by the Salesforce Mobile SDK. External API calls explicitly
     * set requiresAuthentication = true.
     * 
     * ## Header and Body Handling
     * - All original HTTP headers are preserved and transferred
     * - Request body is transferred with JSON content type
     * - Content-Type is set to "application/json; charset=utf-8"
     * 
     * - Parameter request: NetworkRequest containing URL, method, headers, and body
     * - Returns: Tuple containing response data and URLResponse
     * - Throws: NetworkError.invalidURL if request URL is malformed
     *          RestClient errors for network or authentication failures
     * 
     * ## Error Scenarios
     * - Invalid or missing URL throws NetworkError.invalidURL
     * - Authentication failures propagated from RestClient
     * - Network connectivity issues propagated from RestClient
     * - Invalid JSON or malformed requests handled by Salesforce API
     * 
     * ## Performance Considerations
     * - Uses async/await for non-blocking network operations
     * - RestClient handles connection pooling and retries
     * - Response data is returned as-is without additional processing
     */
    public func data(for request: NetworkRequest) async throws -> (Data, URLResponse) {
        // Validate that the request contains a valid URL
        guard let url = request.baseRequest.url else {
            throw NetworkError.invalidURL
        }
        
        // Extract HTTP method, defaulting to GET if not specified
        let method = request.baseRequest.httpMethod ?? "GET"
        let path = url.path

        let restRequest: RestRequest
        
        if let host = url.host {
            // Handle external Einstein API requests with full URLs
            // Example: "https://api.salesforce.com/einstein/ai-agent/v1/agents/0XxQy000000BD0LKAW/sessions"
            restRequest = RestRequest.customUrlRequest(
                with: RestRequest.sfRestMethod(fromHTTPMethod: method),
                baseURL: "https://\(host)",
                path: url.path(),
                queryParams: nil
            )
            // Ensure authentication is required for external API calls
            restRequest.requiresAuthentication = true
           
            // Transfer all original headers to the RestRequest
            if let headers = request.baseRequest.allHTTPHeaderFields {
                restRequest.customHeaders = NSMutableDictionary(dictionary: headers)
            }
        } else {
            // Handle internal Salesforce API requests with relative paths
            // Example: "/services/data/v62.0/connect/conversation-runtime-proxy"
            restRequest = RestRequest(
                method: RestRequest.sfRestMethod(fromHTTPMethod: method),
                path: path,
                queryParams: nil
            )
        }
        
        // Transfer request body data if present, setting JSON content type
        if let httpBody = request.baseRequest.httpBody {
            restRequest.setCustomRequestBodyData(
                httpBody,
                contentType: "application/json; charset=utf-8"
            )
        }
        
        // Execute the request using Salesforce RestClient and return response
        let response = try await RestClient.shared.send(request: restRequest)
        return (response.asData(), response.urlResponse)
    }
}
