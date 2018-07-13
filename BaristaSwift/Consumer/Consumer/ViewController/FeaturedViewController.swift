/*
  FeaturedViewController.swift
  Consumer

  Created by David Vieser on 2/6/18.

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
import SalesforceSwiftSDK
import PromiseKit

class FeaturedViewController: UIViewController {

    @IBOutlet weak var featuredProductTableView: UITableView!
    fileprivate var refreshControl = UIRefreshControl()
    fileprivate var gradientView = GradientView()

    var featuredProducts: [Product?] = [] {
        didSet {
            self.featuredProductTableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let gradientLayer = self.gradientView.layer as! CAGradientLayer
        gradientLayer.colors = [Theme.productConfigTopBgGradColor.cgColor, Theme.productConfigBottomBgGradColor.cgColor]
        self.view.insertSubview(self.gradientView, at: 0)
        
        self.gradientView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.gradientView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.gradientView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.gradientView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
        self.featuredProductTableView.tableFooterView = UIView()
        self.featuredProducts = ProductStore.instance.featuredProducts()
        self.featuredProductTableView.backgroundColor = UIColor.clear
        
        self.refreshControl.tintColor = UIColor.white
        self.refreshControl.addTarget(self, action: #selector(updateFeaturedProducts), for: .valueChanged)
        self.featuredProductTableView.refreshControl = self.refreshControl
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }

    @objc func updateFeaturedProducts() {
        _ = ProductStore.instance.syncDown()
            .done { _ in
                DispatchQueue.main.async {
                    self.refreshControl.endRefreshing()
                    self.featuredProducts = ProductStore.instance.featuredProducts()
                    self.featuredProductTableView.reloadData()
                }
            }
    }
}

extension FeaturedViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return featuredProducts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "FeaturedProductCell"
        
        // Dequeue or create a cell of the appropriate type.
        let cell: FeaturedProductTableViewCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! FeaturedProductTableViewCell
        
        // Configure the cell to show the data.
        if let product: Product = featuredProducts[indexPath.row] {
            cell.name = product.name
            cell.imageURL = indexPath.row % 2 == 0 ? product.featuredImageRightURL : product.featuredImageLeftURL
            cell.nameLabel.textAlignment = indexPath.row % 2 == 0 ? .left : .right
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let product = self.featuredProducts[indexPath.row] else { return }
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
