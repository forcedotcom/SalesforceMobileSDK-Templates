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

import SalesforceSDKCore
import Combine

/**
  Error used by Combine friendly send:request method in RestClient extension below
 */
enum RequestError: Error {
    case httpError(code: Int, error: Error?)
    case emptyResponse
    case unknown
}

/**
 RestClient extension that adds a send:request method returning a Combine Publisher
 */
extension RestClient {
    
    /**
        Send a request and return a Future Publisher to consume the response
        @param request:RestRequest
        @return a Future<[[String:Any]], RequestError> Publisher
     */
    func send(request: RestRequest) -> Future<[[String:Any]], RequestError> {
        Future<[[String:Any]], RequestError> { promise in
            self.send(request: request,
                      onFailure: { (error, urlResponse) in
                        if let httpUrlResponse = urlResponse as? HTTPURLResponse {
                            promise(.failure(.httpError(code:httpUrlResponse.statusCode, error:error)))
                        } else {
                            promise(.failure(.unknown))
                        }
            },
                      onSuccess: { (response, urlresponse) in
                        if let jsonResponse = response as? [String:Any],
                            let result = jsonResponse ["records"] as? [[String:Any]]  {
                            promise(.success(result))
                        } else {
                            promise(.failure(.emptyResponse))
                        }
            })
        }
    }
    
}
