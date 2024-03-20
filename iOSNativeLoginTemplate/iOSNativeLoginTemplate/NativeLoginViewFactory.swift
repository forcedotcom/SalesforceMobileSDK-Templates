//
//  NativeLoginViewFactory.swift
//  SalesforceSDKCore
//
//  Created by Brandon Page on 12/18/23.
//  Copyright (c) 2023-present, salesforce.com, inc. All rights reserved.
//
//  Redistribution and use of this software in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//  * Redistributions of source code must retain the above copyright notice, this list of conditions
//  and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright notice, this list of
//  conditions and the following disclaimer in the documentation and/or other materials provided
//  with the distribution.
//  * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
//  endorse or promote products derived from this software without specific prior written
//  permission of salesforce.com, inc.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
//  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
//  WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Foundation
import SwiftUI

class NativeLoginViewFactory: NSObject {
    
    static func create(
        reCaptchaClientObservable: ReCaptchaClientObservable
    ) -> UIViewController {
        let view = NativeLoginTemplateHostingController(rootView: NativeLoginView()
            .environmentObject(reCaptchaClientObservable))
        
        return view
    }
}

class NativeLoginTemplateHostingController<Content>: UIHostingController<Content> where Content : View {
    
    override func willMove(toParent parent: UIViewController?) {
        
        guard let navigationController = (parent as? UINavigationController) else {
            return
        }
        
        //
        // The Salesforce Mobile SDK provided navigation controller displays a
        // navigation bar that is redundant with the SwiftUI navigation in the
        // template app, so hide it.
        //
        // TODO: See if this should be resolved in SFMSDK. ECJ20240516
        //
        navigationController.setNavigationBarHidden(true, animated: true)
    }
}
