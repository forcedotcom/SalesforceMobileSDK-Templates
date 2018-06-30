//
//  ProductViewController.swift
//  Consumer
//
//  Created by David Vieser on 1/31/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import UIKit
import Common

class ProductViewController: UIViewController {

    var productSelectedSegueName = "ProductSelectedSegue"
    
    @IBOutlet weak var productTableView: UITableView!
    
    var products: [Product?] = []
    
    var category: ProductCategory? = nil {
        didSet {
            self.products = ProductStore.instance.records(for: self.category)
        }
    }
    
    override func loadView()
    {
        super.loadView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = category?.name
        self.productTableView.tableFooterView = UIView()
        self.productTableView.separatorInset = UIEdgeInsets.zero
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.updateCartButton()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func updateCartButton() {
        let cartCount = LocalCartStore.instance.cartCount()
        if  cartCount > 0 {
            let button = UIButton(type: .custom)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setBackgroundImage(UIImage(named: "cart_selected"), for: .normal)
            button.addTarget(self, action: #selector(didPressCartButton), for: .touchUpInside)
            button.titleLabel?.font = Theme.cartButtonFont
            button.setTitleColor(UIColor.white, for: .normal)
            button.setTitle("\(cartCount)", for: .normal)
            
            let barButton = UIBarButtonItem(customView: button)
            self.navigationItem.rightBarButtonItem = barButton
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
    }
    
    @objc func didPressCartButton() {
        let items = LocalCartStore.instance.currentCart()
        let cart = CartViewController(cart: items, cartStore: LocalCartStore.instance)
        self.navigationController?.pushViewController(cart, animated: true)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination: ProductConfigureViewController = segue.destination as?
            ProductConfigureViewController, let product: Product = sender as? Product, let cat = self.category {
            destination.product = product
            if let families = ProductOptionStore.instance.families(product) {
                destination.productFamilies = families
            }
            destination.dismissCompletion = {
                self.updateCartButton()
            }
        }
    }
}

extension ProductViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.products.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "ProductCell"
        
        // Dequeue or create a cell of the appropriate type.
        let cell: ProductTableViewCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ProductTableViewCell
        
        // Configure the cell to show the data.
        if let product: Product = self.products[indexPath.row] {
            cell.name = product.name
            cell.price = "FREE" // todo pull from product price
            cell.imageURL = product.iconImageURL
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: productSelectedSegueName, sender: products[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
