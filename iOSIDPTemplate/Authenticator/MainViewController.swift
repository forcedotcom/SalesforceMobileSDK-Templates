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
import WYPopoverController
import SalesforceSDKCore

class MainViewController: UINavigationController {
    
    var popOverController:WYPopoverController?
    @IBOutlet weak var showPopoverButton: UIBarButtonItem!

    @IBAction func popOverAction(_ sender: UIBarButtonItem) {
        let popOverContent = ActionsPopoverTableViewController(nibName: nil, bundle: nil)
        popOverContent.delegate = self
        popOverContent.preferredContentSize = CGSize(width: 260, height: 90)
        self.popOverController = WYPopoverController(contentViewController: popOverContent)
        self.popOverController?.presentPopover(from: sender, permittedArrowDirections: .any, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func showOtherActions(sender: UIBarButtonItem) {
    }
}

extension MainViewController : ActionsPopoverTableViewDelegate {

    func logoutAllUsersSelected(sender: ActionsPopoverTableViewController) {
        popOverController?.dismissPopover(animated: true)
        showLogoutActionSheet()
    }

    func switchUserSelected(sender: ActionsPopoverTableViewController) {
        popOverController?.dismissPopover(animated: true)
        showSwitchUserSheet()
    }

    func showLogoutActionSheet() {

        let alert = UIAlertController(title: "Logout", message: "Are you sure you want to log out?", preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (result : UIAlertAction) -> Void in
            print("Cancel")
        }

        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
           SFUserAccountManager.sharedInstance().logoutAllUsers()
        }

        alert.addAction(cancelAction)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func showErrorActionSheet() {
        
        let alert = UIAlertController(title: "Error", message: "Error adding a User", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
            SFUserAccountManager.sharedInstance().logoutAllUsers()
        }
        
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }

    func showSwitchUserSheet() {
        SFUserAccountManager.sharedInstance().login(completion: { (authInfo, account) in
            
        }) { (authInfo, error) in
            
        }
    }
}
