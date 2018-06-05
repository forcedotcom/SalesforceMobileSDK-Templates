/*
 Copyright (c) 2017-present, salesforce.com, inc. All rights reserved.
 
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
import UIKit
import SalesforceSDKCore

class AppsViewController: UIViewController {

    @IBOutlet weak var appOneButton: UIButton!

    @IBOutlet weak var appTwoButton: UIButton!
    
    @IBAction func toolBarAction(_ sender: Any) {
       let controller =  self.navigationController as! MainViewController
       controller.popOverAction(sender as! UIBarButtonItem)
    }
    
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBAction func appOneButtonAction(_ sender: Any) {
        //change these to reflect the schemes of apps you would like to initiate from the
        //authenticator
        launchSPApp(appUrl: "sampleapp")
    }
    
    @IBAction func appTwoButtonAction(_ sender: Any) {
        //change these to reflect the schemes of apps you would like to initiate from the
        //authenticator
        launchSPApp(appUrl: "sampleapptwo")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.messageLabel.text = "Launch app as user\n" + (SFUserAccountManager.sharedInstance().currentUser?.fullName)!;
        self.messageLabel.textAlignment = .center;
        self.messageLabel.font = messageLabel.font.withSize(16);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func launchSPApp(appUrl :String) {
        let userAccount = SFUserAccountManager.sharedInstance().currentUser
        let userHint =  (userAccount?.accountIdentity.userId)! + ":" + (userAccount?.accountIdentity.orgId)!
        let urlString = appUrl + "://oauth2/v1.0/idpinit?user_hint=" + userHint + "&login_host=" + (userAccount?.credentials.domain)!
        let url = URL(string: urlString)
        SFApplicationHelper.open(url!)
    }
}
