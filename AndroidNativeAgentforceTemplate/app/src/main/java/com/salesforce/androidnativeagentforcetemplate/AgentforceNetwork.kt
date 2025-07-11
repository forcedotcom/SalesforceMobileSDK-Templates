/*
 * Copyright (c) 2012-present, salesforce.com, inc.
 * All rights reserved.
 * Redistribution and use of this software in source and binary forms, with or
 * without modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 * - Neither the name of salesforce.com, inc. nor the names of its contributors
 * may be used to endorse or promote products derived from this software without
 * specific prior written permission of salesforce.com, inc.
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
package com.salesforce.androidnativeagentforcetemplate

import com.salesforce.android.mobile.interfaces.network.Network
import com.salesforce.android.mobile.interfaces.network.NetworkRequest
import com.salesforce.android.mobile.interfaces.network.NetworkResponse
import com.salesforce.androidsdk.rest.RestClient
import com.salesforce.androidsdk.rest.RestRequest
import com.salesforce.androidsdk.rest.RestResponse
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import java.net.URLEncoder
import java.nio.charset.StandardCharsets
import java.util.concurrent.TimeUnit
import kotlin.coroutines.suspendCoroutine

class AgentforceNetwork(private val restClient: RestClient) : Network {

    override suspend fun perform(request: NetworkRequest): NetworkResponse {
        return suspendCoroutine { continuation ->
            restClient.sendAsync(
                request.toRestRequest(),
                object : RestClient.AsyncRequestCallback {
                    override fun onSuccess(req: RestRequest?, resp: RestResponse?) {
                        continuation.resumeWith(Result.success(processResponse(resp, request)))
                    }

                    override fun onError(exception: Exception?) {
                        continuation.resumeWith(Result.success(NetworkResponse(request, 404)))
                    }
                }
            )
        }
    }

    fun processResponse(resp: RestResponse?, request: NetworkRequest): NetworkResponse {
        return NetworkResponse(
            request,
            resp?.statusCode ?: NetworkResponse.STATUS_CODE_UNKNOWN,
            resp?.allHeaders ?: emptyMap(),
            resp?.asBytes()
        )
    }
}

/**
 * Convert the MobileExtensionSDK NetworkRequest to MobileSDK RestRequest
 */
fun NetworkRequest.toRestRequest(): RestRequest {
    val method = method.restMethod
    return RestRequest(
        method, relativeUri,
        if (body != null && body!!.isNotEmpty()) {

            // parse content type if exists
            when (contentType == null) {
                false -> body!!.toRequestBody(contentType!!.toMediaType(), 0, body!!.size)
                true -> body!!.toRequestBody(null, 0, body!!.size)
            }
        } else {
            null
        },
        additionalHttpHeaders
    )
}

/**
 * Generate the relative uri for the RestRequest treated as path
 */
val NetworkRequest.relativeUri: String
    get() {
        var uri = this.path

        if (queryParams.isNotEmpty()) {
            val queryString = queryParams
                .map {
                    "${it.key}=${
                        URLEncoder.encode(
                            it.value.toString(),
                            StandardCharsets.UTF_8.name()
                        )
                    }"
                }
                .joinToString("&")
            uri += "?$queryString"
        }

        return uri
    }

/**
 * Convert the MobileExtensionSDK NetworkRequest.Method to MobileSDK RestRequest.RestMethod
 */
val NetworkRequest.Method.restMethod: RestRequest.RestMethod
    get() {
        return when (this) {
            NetworkRequest.Method.GET -> RestRequest.RestMethod.GET
            NetworkRequest.Method.POST -> RestRequest.RestMethod.POST
            NetworkRequest.Method.PUT -> RestRequest.RestMethod.PUT
            NetworkRequest.Method.DELETE -> RestRequest.RestMethod.DELETE
            NetworkRequest.Method.HEAD -> RestRequest.RestMethod.HEAD
            NetworkRequest.Method.PATCH -> RestRequest.RestMethod.PATCH
        }
    }