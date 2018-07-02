/*
  FavoritesViewController.swift
  Consumer

  Created by Nicholas McDonald on 3/19/18.

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
import Common

class FavoritesViewController: UIViewController {
    
    let tableView = UITableView(frame: .zero, style: .plain)
    var favorites:[UserFavorite?] = []
    fileprivate var gradientView = GradientView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gradientLayer = self.gradientView.layer as! CAGradientLayer
        gradientLayer.colors = [Theme.productConfigTopBgGradColor.cgColor, Theme.productConfigBottomBgGradColor.cgColor]
        self.view.insertSubview(self.gradientView, at: 0)
        
        self.gradientView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.gradientView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.gradientView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.gradientView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
        self.favorites = FavoritesStore.instance.myFavorites()
        
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.separatorColor = UIColor(white: 0.0, alpha: 0.3)
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.register(CartItemTableViewCell.self, forCellReuseIdentifier: "itemCell")
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.estimatedRowHeight = 40.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.view.addSubview(self.tableView)
        
        self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        FavoritesStore.instance.syncDown { (syncState) in
            if let complete = syncState?.isDone(), complete == true {
                DispatchQueue.main.async {
                    self.favorites = FavoritesStore.instance.myFavorites()
                    self.tableView.reloadData()
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension FavoritesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 100.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let favorite = self.favorites[indexPath.row],
            let productId = favorite.productId,
            let product = ProductStore.instance.product(from: productId) else { return }
        let storyboard = UIStoryboard(name: "ProductConfigureStoryboard", bundle: nil)
        if let configVC = storyboard.instantiateInitialViewController() as? ProductConfigureViewController {
            configVC.product = product
            if let families = ProductOptionStore.instance.families(product) {
                configVC.productFamilies = families
            }
            configVC.dismissCompletion = {
                
            }
            configVC.modalTransitionStyle = .coverVertical
            configVC.modalPresentationStyle = .overCurrentContext
            self.tabBarController?.present(configVC, animated: true, completion: nil)
        }
    }
}

extension FavoritesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.favorites.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // stealing cart cell until we have time to finish out UI
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell") as! CartItemTableViewCell
        guard let item = self.favorites[indexPath.row], let productId = item.productId else {return cell}
        let product = ProductStore.instance.product(from: productId)
        cell.itemName = product?.name

        return cell
    }
}
