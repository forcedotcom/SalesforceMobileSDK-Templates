/*
 ViewController.swift
 MobileSyncExplorerSwift

 Created by Nicholas McDonald on 1/16/18.

 Copyright (c) 2018-present, salesforce.com, inc. All rights reserved.
 
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
import CoreGraphics
import MobileSync

class RootViewController: UniversalViewController {
    
    weak var presentedActions:AdditionalActionsViewController?
    weak var logoutAlert:UIAlertController?
    
    fileprivate var searchText:String = ""
    fileprivate let tableView = UITableView(frame: .zero, style: .plain)
    fileprivate let searchController = UISearchController(searchResultsController: nil)
    fileprivate var sObjectsDataManager = SObjectDataManager(dataSpec: ContactSObjectData.dataSpec()!)
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.salesforceSystemBackground
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(clearPopoversForPasscode),
                                               name: NSNotification.Name(rawValue: kSFPasscodeFlowWillBegin),
                                               object: nil)
        
        self.title = "MobileSync Explorer"
        
        guard let settings = UIImage(named: "setting")?.withRenderingMode(.alwaysOriginal),
            let sync = UIImage(named: "sync")?.withRenderingMode(.alwaysOriginal),
            let add = UIImage(named: "plusButton")?.withRenderingMode(.alwaysOriginal) else { return }
        let settingsButton = UIBarButtonItem(image: settings, style: .plain, target: self, action: #selector(showAdditionalActions(_:)))
        let syncButton = UIBarButtonItem(image: sync, style: .plain, target: self, action: #selector(didPressSyncUpDown))
        let addButton = UIBarButtonItem(image: add, style: .plain, target: self, action: #selector(didPressAddContact))
        self.navigationItem.rightBarButtonItems = [settingsButton, syncButton, addButton]
        
        self.searchController.searchResultsUpdater = self
        self.searchController.obscuresBackgroundDuringPresentation = false
        self.definesPresentationContext = true
        
        self.tableView.tableHeaderView = self.searchController.searchBar
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.separatorColor = UIColor.appSeparator
        self.tableView.register(ContactTableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.view.addSubview(self.tableView)
        
        let safe = self.view.safeAreaLayoutGuide
        self.commonConstraints.append(contentsOf: [self.tableView.leftAnchor.constraint(equalTo: safe.leftAnchor),
                                                   self.tableView.rightAnchor.constraint(equalTo: safe.rightAnchor),
                                                   self.tableView.topAnchor.constraint(equalTo: safe.topAnchor),
                                                   self.tableView.bottomAnchor.constraint(equalTo: safe.bottomAnchor)])

       
        
       
        super.applyConstraints()
        syncUpDown()
    }

    @objc func showAdditionalActions(_ sender: UIBarButtonItem) {
        let table = AdditionalActionsViewController()
        table.modalPresentationStyle = .popover
        table.preferredContentSize = CGSize(width: 200.0, height: 132.0)
        table.onLogoutSelected = {
            table.dismiss(animated: true, completion: {
                self.showLogoutActionSheet()
            })
        }
        table.onSwitchUserSelected = {
            table.dismiss(animated: true, completion: {
                self.showSwitchUserController()
            })
        }
        table.onDBInspectorSelected = {
            table.dismiss(animated: true, completion: {
                self.showDBInspector()
            })
        }
        table.onCancelSelected = {
            table.dismiss(animated: true, completion: nil)
        }
        
        self.present(table, animated: true, completion: nil)
        self.presentedActions = table
        let popover = table.popoverPresentationController
        popover?.barButtonItem = sender
    }
    
    @objc func didPressAddContact() {
        let detailVC = ContactDetailViewController( nil,objectManager: sObjectsDataManager ,completion: {
             self.refreshList()
        })
        detailVC.detailViewDelegate = self
        self.navigationController?.pushViewController(detailVC, animated: true)
    }
    
    @objc func didPressSyncUpDown() {
        syncUpDown()
    }
    
    func syncUpDown(){
        let alert = self.showAlert("Syncing", message: "Syncing with Salesforce")
        sObjectsDataManager.updateRemoteData({ [weak self] (sObjectsData) in
            DispatchQueue.main.async {
                alert.message = "Sync Complete!"
                alert.dismiss(animated: true, completion: nil)
                self?.refreshList()
            }
        }, onFailure: { [weak self] (error, syncState) in
            alert.message = "Sync Failed!"
            alert.dismiss(animated: true, completion: nil)
            self?.refreshList()
        })
    }
    
    @objc func clearPopoversForPasscode() {
        SalesforceLogger.d(type(of: self), message: "Passcode screen loading. Clearing popovers")
        
        if let alert = self.logoutAlert {
            alert.dismiss(animated: true, completion: nil)
        }
        
        self.dismissPopover()
    }
    
    func dismissPopover() {
        if let p = self.presentedActions {
            p.dismiss(animated: true, completion: nil)
        }
        if let l = self.logoutAlert {
            l.dismiss(animated: true, completion: nil)
        }
    }
    
    fileprivate func showAlert(_ title:String, message:String) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        self.present(alert, animated: true, completion: nil)
        return alert
    }

    fileprivate func refreshList() {
        self.sObjectsDataManager.filter(onSearchTerm: self.searchText) {[weak self]  dataRows in
             DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
    
    fileprivate func showLogoutActionSheet() {
        let alert = UIAlertController(title: nil, message: "Are you sure you want to log out", preferredStyle: .alert)
        let logout = UIAlertAction(title: "Logout", style: .destructive) { (action) in
            UserAccountManager.shared.logout()
        }
        self.logoutAlert = alert
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(logout)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func showSwitchUserController() {
        let controller = SalesforceUserManagementViewController  { (userManagementAction) in
            self.dismiss(animated: true, completion: nil)
        }
        self.present(controller, animated: true, completion: nil)
    }
    
    fileprivate func showDBInspector() {
        let inspector = InspectorViewController(store: self.sObjectsDataManager.store)
        self.present(inspector, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension RootViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let search = searchController.searchBar.text, search.isEmpty == false {
            self.searchText = search
        } else {
            self.searchText = ""
        }
        self.refreshList()
    }
}

extension RootViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.ContactTableCellHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let contact = self.sObjectsDataManager.dataRows[indexPath.row] as! ContactSObjectData
        let detail = ContactDetailViewController(contact, objectManager: sObjectsDataManager, completion: {
            tableView.beginUpdates()
            tableView.reloadRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
        })
        detail.detailViewDelegate = self
        self.navigationController?.pushViewController(detail, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension RootViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return self.sObjectsDataManager.dataRows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! ContactTableViewCell
        let contact = self.sObjectsDataManager.dataRows[indexPath.row] as! ContactSObjectData

        if (self.sObjectsDataManager.dataLocallyDeleted(contact)) {
            cell.backgroundColor = UIColor.contactCellDeletedBackground
        } else {
            cell.backgroundColor = UIColor.clear
        }
       
        cell.showRefresh = self.sObjectsDataManager.dataLocallyUpdated(contact)
        cell.showCreated = self.sObjectsDataManager.dataLocallyCreated(contact)
        cell.title = ContactHelper.nameStringFromContact(contact)
        cell.subtitle = ContactHelper.titleStringFromContact(contact)
        cell.leftImage = ContactHelper.initialsImage(ContactHelper.colorFromContact(contact), initials: ContactHelper.initialsStringFromContact(contact))
        return cell
    }
}

extension RootViewController: ContactDetailViewDelegate {
   
    func userDidDelete(object: SObjectData) {
        do {
            _ = try self.sObjectsDataManager.deleteLocalData(object)
        } catch let error as NSError {
           MobileSyncLogger.e(RootViewController.self, message: "Delete local data failed \(error)" )
        }
        self.refreshList()
    }
    
    func userDidUndelete(object: SObjectData) {
        do {
           _ = try self.sObjectsDataManager.undeleteLocalData(object)
        } catch let error as NSError {
            MobileSyncLogger.e(RootViewController.self, message: "Undelete local data failed \(error)" )
        }
        self.refreshList()
    }
    
    func userDidUpdate(object: SObjectData) {
        do {
           _ = try self.sObjectsDataManager.updateLocalData(object)
        } catch let error as NSError {
             MobileSyncLogger.e(RootViewController.self, message: "Update local data failed \(error)" )
        }
        self.refreshList()
    }
    
    func userDidAdd(object: SObjectData) {
        do {
            _ = try self.sObjectsDataManager.createLocalData(object)
        } catch let error as NSError{
             MobileSyncLogger.e(RootViewController.self, message: "Add local data failed \(error)" )
        }
        self.refreshList()
    }
}

