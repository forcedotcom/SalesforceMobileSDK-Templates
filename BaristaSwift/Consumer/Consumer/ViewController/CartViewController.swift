/*
  CartViewController.swift
  Consumer

  Created by Nicholas McDonald on 2/12/18.

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

class CartViewController: BaseViewController {
    
    fileprivate var tableView = UITableView(frame: .zero, style: .plain)
    fileprivate var cartItems:[LocalProductItem?]
    fileprivate var cartStore:LocalCartStore
    
    init(cart:[LocalProductItem?], cartStore:LocalCartStore) {
        self.cartItems = cart
        self.cartStore = cartStore
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Check Out"
        self.view.backgroundColor = UIColor.white
        
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.separatorColor = UIColor(white: 0.0, alpha: 0.3)
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.register(CartItemTableViewCell.self, forCellReuseIdentifier: "itemCell")
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.estimatedRowHeight = 40.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.view.addSubview(self.tableView)
        
        let payButton = UIButton(type: .custom)
        payButton.translatesAutoresizingMaskIntoConstraints = false
        payButton.setTitle("PAY", for: .normal)
        payButton.titleLabel?.textColor = UIColor.white
        payButton.titleLabel?.font = Theme.appBoldFont(15.0)
        payButton.backgroundColor = Theme.appAccentColor01
        payButton.addTarget(self, action: #selector(didPressCheckout), for: .touchUpInside)
        self.view.addSubview(payButton)
        
        self.tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.tableView.bottomAnchor.constraint(equalTo: payButton.topAnchor).isActive = true
        
        payButton.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        payButton.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        payButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        payButton.heightAnchor.constraint(equalToConstant: 48.0).isActive = true
    }
    
    @objc func didPressCheckout() {
        let activity = ActivityIndicatorView(frame: .zero)
        activity.showIn(self.view)
        activity.startAnimating()
        self.cartStore.submitOrder { (completed) in
            DispatchQueue.main.async {
                var alert:UIAlertController!
                if completed == true {
                    alert = UIAlertController(title: "Submitted", message: "Your order has been succesfully placed. Thank You.", preferredStyle: .alert)
                } else {
                    alert = UIAlertController(title: "Error", message: "There was a problem submitting your order, please try again. Thank You.", preferredStyle: .alert)
                }
                let ok = UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                    self.navigationController?.popViewController(animated: true)
                })
                alert.addAction(ok)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension CartViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 100.0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = CartFooterView(frame: .zero)
        view.total = "$0.00"
        return view
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }
}

extension CartViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cartItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell") as! CartItemTableViewCell
        guard let item = self.cartItems[indexPath.row], let productId = item.product.productId else {return cell}
        let product = ProductStore.instance.product(from: productId)
        cell.itemName = product?.name
        
        // todo add business logic to handle size cost changes to main item
        // add option prices
        for option in item.options {
            guard let name = option.product.productDescription, let type = option.product.optionType else { continue }
            if type == .integer {
                cell.addOption("(\(option.quantity)) \(name)")
            } else {
                cell.addOption(name)
            }
        }
        cell.price = "FREE"
        return cell
    }
}









