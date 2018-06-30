//
//  AccountViewController.swift
//  Consumer
//
//  Created by David Vieser on 2/5/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import UIKit
import SmartStore
import SalesforceSDKCore
import Common

class AccountViewController: UIViewController {

    @IBAction func smartStoreDebugButtonPressed(_ sender: Any) {
        let smartStoreViewController = SFSmartStoreInspectorViewController.init(store:  SFSmartStore.sharedStore(withName: kDefaultSmartStoreName) as! SFSmartStore)
        present(smartStoreViewController, animated: true, completion: nil)
    }
    
    let tableView = UITableView(frame: .zero, style: .plain)
    fileprivate var gradientView = GradientView()
    fileprivate var containerView = UIView()
    fileprivate let sectionTitles = ["Account", "Security"]
    fileprivate let tableData = [["Personal Info", "Payment Methods"], ["Passcode Lock", "Touch ID"]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let account = AccountStore.instance.myAccount()
        
        let safe = self.view.safeAreaLayoutGuide
        
        let gradientLayer = self.gradientView.layer as! CAGradientLayer
        gradientLayer.colors = [Theme.productConfigTopBgGradColor.cgColor, Theme.productConfigBottomBgGradColor.cgColor]
        self.view.insertSubview(self.gradientView, at: 0)
        
        self.gradientView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.gradientView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.gradientView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.gradientView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
        let rewardButton = UIButton(type: .custom)
        rewardButton.translatesAutoresizingMaskIntoConstraints = false
        rewardButton.setTitle("Rewards", for: .normal)
        rewardButton.setTitleColor(UIColor.white, for: .normal)
        rewardButton.titleLabel?.font = Theme.appBoldFont(15.0)
        rewardButton.addTarget(self, action: #selector(didPressRewardsButton), for: .touchUpInside)
        self.view.addSubview(rewardButton)
        
        let historyButton = UIButton(type: .custom)
        historyButton.translatesAutoresizingMaskIntoConstraints = false
        historyButton.setTitle("History", for: .normal)
        historyButton.setTitleColor(UIColor.white, for: .normal)
        historyButton.titleLabel?.font = Theme.appBoldFont(15.0)
        historyButton.addTarget(self, action: #selector(didPressHistoryButton), for: .touchUpInside)
        self.view.addSubview(historyButton)
        
        let profileButton = UIButton(type: .custom)
        profileButton.translatesAutoresizingMaskIntoConstraints = false
        profileButton.setTitle("Profile", for: .normal)
        profileButton.setTitleColor(UIColor.white, for: .normal)
        profileButton.titleLabel?.font = Theme.appBoldFont(15.0)
        profileButton.addTarget(self, action: #selector(didPressProfileButton), for: .touchUpInside)
        self.view.addSubview(profileButton)
        
        rewardButton.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        historyButton.leftAnchor.constraint(equalTo: rewardButton.rightAnchor).isActive = true
        profileButton.leftAnchor.constraint(equalTo: historyButton.rightAnchor).isActive = true
        profileButton.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        historyButton.widthAnchor.constraint(equalTo: rewardButton.widthAnchor, multiplier: 1.0).isActive = true
        profileButton.widthAnchor.constraint(equalTo: rewardButton.widthAnchor, multiplier: 1.0).isActive = true
        
        rewardButton.topAnchor.constraint(equalTo: safe.topAnchor).isActive = true
        historyButton.topAnchor.constraint(equalTo: rewardButton.topAnchor).isActive = true
        profileButton.topAnchor.constraint(equalTo: rewardButton.topAnchor).isActive = true
        rewardButton.heightAnchor.constraint(equalToConstant: 43.0).isActive = true
        historyButton.heightAnchor.constraint(equalTo: rewardButton.heightAnchor, multiplier: 1.0).isActive = true
        profileButton.heightAnchor.constraint(equalTo: rewardButton.heightAnchor, multiplier: 1.0).isActive = true
        
        let logoutButton = UIButton(type: .custom)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.setTitle("SIGN OUT", for: .normal)
        logoutButton.setTitleColor(UIColor.white, for: .normal)
        logoutButton.titleLabel?.font = Theme.appBoldFont(15.0)
        logoutButton.backgroundColor = Theme.appAccentColor01
        logoutButton.addTarget(self, action: #selector(didPressLogoutButton), for: .touchUpInside)
        self.view.addSubview(logoutButton)
        
        logoutButton.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        logoutButton.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        logoutButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        logoutButton.heightAnchor.constraint(equalToConstant: 48.0).isActive = true
        
        self.containerView.translatesAutoresizingMaskIntoConstraints = false
        self.containerView.backgroundColor = UIColor.white
        self.view.addSubview(self.containerView)
        
        self.containerView.leftAnchor.constraint(equalTo: safe.leftAnchor).isActive = true
        self.containerView.rightAnchor.constraint(equalTo: safe.rightAnchor).isActive = true
        self.containerView.topAnchor.constraint(equalTo: rewardButton.bottomAnchor).isActive = true
        self.containerView.bottomAnchor.constraint(equalTo: logoutButton.topAnchor).isActive = true
        
        let userImageview = UIImageView()
        userImageview.translatesAutoresizingMaskIntoConstraints = false
        self.containerView.addSubview(userImageview)
        
        userImageview.centerXAnchor.constraint(equalTo: self.containerView.centerXAnchor).isActive = true
        userImageview.heightAnchor.constraint(equalToConstant: 100.0).isActive = true
        userImageview.widthAnchor.constraint(equalToConstant: 100.0).isActive = true
        userImageview.topAnchor.constraint(equalTo: self.containerView.topAnchor, constant:60.0).isActive = true
        
        let usernameLabel = UILabel()
        usernameLabel.font = Theme.appMediumFont(15.0)
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.text = account?.name
        self.containerView.addSubview(usernameLabel)
        
        usernameLabel.centerXAnchor.constraint(equalTo: self.containerView.centerXAnchor).isActive = true
        usernameLabel.topAnchor.constraint(equalTo: userImageview.bottomAnchor, constant:10).isActive = true
        
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.separatorColor = UIColor(white: 0.0, alpha: 0.3)
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.register(AccountTableViewCell.self, forCellReuseIdentifier: "itemCell")
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.estimatedRowHeight = 40.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.view.addSubview(self.tableView)
        
        self.tableView.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant:0).isActive = true
        self.tableView.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor).isActive = true
        self.tableView.leftAnchor.constraint(equalTo: self.containerView.leftAnchor).isActive = true
        self.tableView.rightAnchor.constraint(equalTo: self.containerView.rightAnchor).isActive = true
        
        self.view.layoutIfNeeded()
        
        userImageview.round()
    }
    
    @objc func didPressRewardsButton() {
        
    }
    
    @objc func didPressHistoryButton() {
        
    }
    
    @objc func didPressProfileButton() {
        
    }
    
    @objc func didPressLogoutButton() {
        SFUserAccountManager.sharedInstance().logout()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension AccountViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 70.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = AccountHeaderView(frame: .zero)
        view.name = self.sectionTitles[section]
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1.0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let line = UIView()
        line.backgroundColor = UIColor(displayP3Red: 0.0, green: 0.0, blue: 0.0, alpha: 0.1)
        return line
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
}

extension AccountViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sectionTitles.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionData = self.tableData[section]
        return sectionData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell") as! AccountTableViewCell
        let section = self.tableData[indexPath.section]
        let name = section[indexPath.row]
        
        cell.name = name
        
        return cell
    }
}
