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

struct SenderAvatar: View {
    let sender: MessageSender
    
    func imageName() -> String {
        switch sender {
        case .user:
            return "figure.pool.swim"
        case .agent:
            return "headset"
        }
    }
    
    func backgroundColor() -> Color {
        switch sender {
        case .user:
            return Color(red: 87/255, green: 139/255, blue: 150/255)
        case .agent:
            return Color(red: 241/255, green: 157/255, blue: 138/255)
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
               .fill(backgroundColor())
               .frame(width: 40, height: 40)
            
            Image(systemName: imageName())
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25)
                .foregroundStyle(.white)
        }
    }
}


struct MessageCell: View {
    let message: ChatMessage
 
    var body: some View {
        HStack(alignment: .top) {
            if  message.sender == .agent {
                SenderAvatar(sender: message.sender)
            }
           
            VStack(alignment: .leading) {
                if message.messageType == .progressIndicator {
                    HStack(spacing: 0) {
                        Text(message.content)
                            .font(.system(size: 16, weight: .regular)).italic()
                        AnimatedEllipsis()
                    }
                    .foregroundStyle(Color(red: 106/255, green: 106/255, blue: 106/255))
                    .padding(10)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                        .fill(message.sender == .agent ? .white : Color(red: 87/255, green: 139/255, blue: 150/255))
                        .shadow(radius: 3)
                    }
                    
                } else {
                    VStack(spacing: 0) {
                        if message.content.isEmpty {
                            AnimatedEllipsis()
                        } else {
                            Text(.init(message.content))
                        }
                    }
                    // Alternate init for markdown support
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(message.sender == .agent ? .black : .white)
                    .lineSpacing(2)
                    .padding(10)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(message.sender == .agent ? .white : Color(red: 87/255, green: 139/255, blue: 150/255))
                            .shadow(radius: 3)
                    }
                }
            }
        }.frame(maxWidth: .infinity, alignment: message.sender == .agent ? .leading : .trailing)
    }
}
