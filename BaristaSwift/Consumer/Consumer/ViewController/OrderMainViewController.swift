/*
  OrderMainViewController.swift
  Consumer

  Created by David Vieser on 1/31/18.

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
import SalesforceSDKCore
import Common

class OrderMainViewController: BaseViewController {
    
    @IBOutlet weak var featuredItemImageView: UIImageView!
    @IBOutlet weak var categoryCollectionView: UICollectionView!
    @IBOutlet weak var featuredItemLabel: UILabel!
    @IBOutlet weak var featuredProductNameLabel: UILabel!
    
    fileprivate var cartButton:UIButton!
    
    let productSegue = "ProductSegue"
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        featuredItemImageView.mask(offset: 50, direction: .convex, side: .bottom)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updateCartButton()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.featuredItemLabel.font = Theme.appBoldFont(14.0)
        featuredItemLabel.textColor = UIColor.white
        featuredItemLabel.text = ""

        self.featuredProductNameLabel.font = Theme.appMediumFont(22.0)
        featuredProductNameLabel.textColor = UIColor.white
        featuredProductNameLabel.text = ""
        
        let safe = self.view.safeAreaLayoutGuide
        
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setBackgroundImage(UIImage(named: "cart_unselected"), for: .normal)
        button.addTarget(self, action: #selector(didPressCartButton), for: .touchUpInside)
        button.titleLabel?.font = Theme.cartButtonFont
        button.setTitleColor(UIColor.black, for: .normal)
        self.view.addSubview(button)
        button.topAnchor.constraint(equalTo: safe.topAnchor).isActive = true
        button.rightAnchor.constraint(equalTo: safe.rightAnchor, constant: -8).isActive = true
        button.heightAnchor.constraint(equalToConstant: 30.0).isActive = true
        button.widthAnchor.constraint(equalTo: button.heightAnchor, multiplier: 1.0).isActive = true
        button.alpha = 0.0
        self.cartButton = button

        if let featuredProduct: Product = ProductStore.instance.featuredProduct(), let firstFeaturedProdcutURL = featuredProduct.featuredImageRightURL {
            DispatchQueue.main.async(execute: {
                self.featuredItemImageView.loadImageUsingCache(withUrl: firstFeaturedProdcutURL)
                self.featuredItemLabel.text = "FEATURED ITEM:"
                self.featuredProductNameLabel.text = featuredProduct.name
            })
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapFeaturedItem))
        self.featuredItemImageView.addGestureRecognizer(tap)
    }
    
    func updateCartButton() {
        let cartCount = LocalCartStore.instance.cartCount()
        self.cartButton.alpha = CGFloat(cartCount)
        self.cartButton.setTitle("\(cartCount)", for: .normal)
    }
    
    @objc func didPressCartButton() {
        let items = LocalCartStore.instance.currentCart()
        let cart = CartViewController(cart: items, cartStore: LocalCartStore.instance)
        self.navigationController?.pushViewController(cart, animated: true)
    }
    
    @objc func didTapFeaturedItem() {
        guard let featured = ProductStore.instance.featuredProduct() else { return }
        let storyboard = UIStoryboard(name: "ProductConfigureStoryboard", bundle: nil)
        if let configVC = storyboard.instantiateInitialViewController() as? ProductConfigureViewController {
            configVC.product = featured
            if let families = ProductOptionStore.instance.families(featured) {
                configVC.productFamilies = families
            }
            configVC.dismissCompletion = {
                self.updateCartButton()
            }
            configVC.modalTransitionStyle = .coverVertical
            configVC.modalPresentationStyle = .overCurrentContext
            self.tabBarController?.present(configVC, animated: true, completion: nil)
        }
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController: ProductViewController = segue.destination as? ProductViewController,
            let category: ProductCategory = sender as? ProductCategory {
            destinationViewController.category = category
        }
    }
}

extension OrderMainViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Int(CategoryStore.instance.count)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellIdentifier = "ItemCell"
        
        // Dequeue or create a cell of the appropriate type.
        let cell: CategoryCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! CategoryCollectionViewCell
        
        // Configure the cell to show the data.
        let category = CategoryStore.instance.record(index: indexPath.item)
        cell.categoryName = category.name
        cell.categoryImageURL = category.iconImageURL
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: productSegue, sender: CategoryStore.instance.record(index: indexPath.item))
    }
}
