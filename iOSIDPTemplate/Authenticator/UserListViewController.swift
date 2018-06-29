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
import SwipeCellKit

class UserListViewController: UITableViewController,UserTableViewCellDelegate, SwipeTableViewCellDelegate {
    
    struct LoginHostAccount {
        var hostName: String
        var userAccount: SFUserAccount
    }
    
    let cellIdentifier = "mycell"
    var groups : Dictionary<String, Array<LoginHostAccount>>?
    var groupIds : [String] = []
   
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @IBAction func toolbarItemAction(_ sender: Any) {
        let controller =  self.navigationController as! MainViewController
        controller.popOverAction(sender as! UIBarButtonItem)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleUserDidLogin(notification:)), name:NSNotification.Name(rawValue: kSFNotificationUserDidLogIn) , object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleUserDidLogout(notification:)), name:NSNotification.Name(rawValue: kSFNotificationUserDidLogout) , object: nil)
        
        self.tableView.rowHeight = 80
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "UserTableViewCell", bundle: bundle)
        self.tableView.register(nib, forCellReuseIdentifier: cellIdentifier)
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "headerfooterview")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.reloadData()
    }
    
    func reloadData(){
        let userAccountLists = SFUserAccountManager.sharedInstance().allUserAccounts()!
        var userAccounts: [LoginHostAccount] = []
        groups?.removeAll()
        groupIds.removeAll()
        userAccountLists.forEach { (account) in
            userAccounts.append(LoginHostAccount(hostName: account.credentials.domain!, userAccount: account))
        }
        self.groups = userAccounts.groupBy{$0.hostName}
        self.groups?.keys.forEach({ (groupName) in
            groupIds.append(groupName)
        })
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return groupIds.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let userAccounts = self.groups![groupIds[section]]
        return  userAccounts!.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! UserTableViewCell
        let userAccounts = self.groups![groupIds[indexPath.section]]
        if( SFUserAccountManager.sharedInstance().currentUser?
            .accountIdentity.isEqual(userAccounts![indexPath.row].userAccount.accountIdentity))! {
            result.currentUserImage.isHidden = false;
        } else {
            result.currentUserImage.isHidden = true;
        }
        result.tableDelegate = self
        result.delegate = self;
        result.user = userAccounts?[indexPath.row].userAccount
        result.userFullName.text = userAccounts?[indexPath.row].userAccount.fullName
        result.email.text = userAccounts?[indexPath.row].userAccount.userName
        let imageName = (userAccounts?[indexPath.row].userAccount.idData?.firstName?.lowercased()) ?? "placeholder"
        result.userPicture.image = UIImage(named: imageName) ?? UIImage(named: "placeholder")
        return result
    }
    
    func logoutUser(user: SFUserAccount) {
        SFUserAccountManager.sharedInstance().logoutUser(user)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        var action:SwipeAction?
        let userAccounts = self.groups![groupIds[indexPath.section]]
        if (orientation == .right) {
            action = SwipeAction(style: .destructive, title: "Logout") { action, indexPath in
                self.logoutUser(user: (userAccounts?[indexPath.row].userAccount)!)
                self.reloadData()
            }
            action?.image = UIImage(named: "Logout")
        } else {
            action = SwipeAction(style: .default, title: "Make Current") { action, indexPath in
                SFUserAccountManager.sharedInstance().switch(toUser: userAccounts?[indexPath.row].userAccount);
                self.reloadData()
            }
            action?.backgroundColor = UIColor(red: 94/255, green: 232/255, blue: 9/255, alpha: 1.0)
            action?.image = UIImage(named: "Current")
        }
        return [action!]
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerLabel  = groupIds[section]
        let headerFooterView = UITableViewHeaderFooterView(reuseIdentifier: "headerfooterview")
        headerFooterView.textLabel?.text = headerLabel
        headerFooterView.textLabel?.textColor = UIColor.black
        return headerFooterView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    @objc func handleUserDidLogout( notification : Notification ) {
        self.reloadData()
    }
    
    @objc func handleUserDidLogin( notification : Notification ) {
        self.reloadData()
    }
}
