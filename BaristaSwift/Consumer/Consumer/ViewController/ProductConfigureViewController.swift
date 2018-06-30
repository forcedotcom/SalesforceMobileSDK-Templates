//
//  ProductConfigureViewController.swift
//  Consumer
//
//  Created by David Vieser on 2/7/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import UIKit
import Common

class ProductConfigureViewController: UIViewController {

    var orderItem: OrderItem?
    var product: Product? {
        didSet {
            guard let p = product else {return}
            let item = LocalProductItem(product: p, options: [], quantity: 1)
            LocalCartStore.instance.beginConfiguring(item)
        }
    }
    var productFamilies: [ProductFamily] = [] {
        didSet {
            for family in productFamilies {
                for option in family.options {
                    if let selected = option.selected, selected == true, let quantity = option.defaultQuantity {
                        let defaultOption = LocalProductOption(product: option, quantity: quantity)
                        LocalCartStore.instance.updateInProgressItem(defaultOption)
                    }
                }
            }
        }
    }
    var dismissCompletion: (() -> Void)?
    
    fileprivate static let curveMaskHeight:CGFloat = 50.0
    fileprivate var gradientView = GradientView()
    @IBOutlet weak var productImageView: UIImageView!
    fileprivate var productSubImageView = UIImageView()
    @IBOutlet weak var productConfigureContainerView: UIView!
    @IBOutlet weak var productNameLabel: UILabel!
    @IBOutlet weak var productPriceLabel: UILabel!
    @IBOutlet weak var productDescriptionLabel: UILabel!
    @IBOutlet weak var attributeTableView: UITableView!
    @IBOutlet weak var dividerView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var addToCartButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(white: 0.0, alpha: 0.6)
        
        let gradientLayer = self.gradientView.layer as! CAGradientLayer
        gradientLayer.colors = [Theme.productConfigTopBgGradColor.cgColor, Theme.productConfigBottomBgGradColor.cgColor]
        self.productConfigureContainerView.insertSubview(self.gradientView, at: 0)

        self.productNameLabel.font = Theme.productConfigItemNameFont
        self.productNameLabel.textColor = Theme.productConfigTextColor

        self.productPriceLabel.font = Theme.productConfigItemPriceFont
        self.productPriceLabel.textColor = Theme.productConfigTextColor

        self.productDescriptionLabel.font = Theme.productConfigItemDescriptionFont
        self.productDescriptionLabel.textColor = Theme.productConfigTextColor

        self.attributeTableView.backgroundColor = UIColor.clear
        self.attributeTableView.separatorColor = Theme.productConfigTableSeparatorColor
        self.attributeTableView.separatorInset = UIEdgeInsets.zero
        self.attributeTableView.register(ProductConfigureTableViewCell.self, forCellReuseIdentifier: "itemCell")
        self.attributeTableView.delegate = self
        self.attributeTableView.dataSource = self
        self.attributeTableView.estimatedRowHeight = 40.0
        self.attributeTableView.rowHeight = UITableViewAutomaticDimension
        self.attributeTableView.tableFooterView = UIView()
        
        self.dividerView.backgroundColor = Theme.productConfigDividerColor
        
        self.addToCartButton.backgroundColor = Theme.productConfigAddToCartColor
        self.addToCartButton.setTitleColor(Theme.cartAddButtonTextColor, for: .normal)
        self.addToCartButton.titleLabel?.font = Theme.productConfigButtonFont
        
        self.cancelButton.backgroundColor = Theme.productConfigCancelAddToCartColor
        self.cancelButton.titleLabel?.font = Theme.productConfigButtonFont
        self.cancelButton.setTitleColor(Theme.cartCancelButtonTextColor, for: .normal)
        
        self.productImageView.clipsToBounds = true
        self.productImageView.image = UIImage(named: "detailBg")
        self.productImageView.layer.borderColor = Theme.productConfigTopBgGradColor.cgColor
        self.productImageView.layer.borderWidth = 4.0
        
        self.productSubImageView.translatesAutoresizingMaskIntoConstraints = false
        self.productSubImageView.contentMode = .scaleAspectFit
        self.productImageView.addSubview(self.productSubImageView)
        self.productSubImageView.loadImageUsingCache(withUrl: self.product?.iconImageURL)
        
        self.productSubImageView.leftAnchor.constraint(equalTo: self.productImageView.leftAnchor, constant: 12.0).isActive = true
        self.productSubImageView.rightAnchor.constraint(equalTo: self.productImageView.rightAnchor, constant: -12.0).isActive = true
        self.productSubImageView.topAnchor.constraint(equalTo: self.productImageView.topAnchor, constant: 12.0).isActive = true
        self.productSubImageView.bottomAnchor.constraint(equalTo: self.productImageView.bottomAnchor, constant: -12.0).isActive = true
        
        self.gradientView.leftAnchor.constraint(equalTo: self.productConfigureContainerView.leftAnchor).isActive = true
        self.gradientView.rightAnchor.constraint(equalTo: self.productConfigureContainerView.rightAnchor).isActive = true
        self.gradientView.topAnchor.constraint(equalTo: self.productConfigureContainerView.topAnchor).isActive = true
        self.gradientView.bottomAnchor.constraint(equalTo: self.productConfigureContainerView.bottomAnchor).isActive = true
        
        self.view.layoutIfNeeded()
        
        self.productImageView.round()
        
        self.productNameLabel.text = self.product?.name
        self.productPriceLabel.text = "Free" // TODO pull from pricebook
        self.productDescriptionLabel.text = self.product?.productDescription
        
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.productConfigureContainerView.mask(offset: ProductConfigureViewController.curveMaskHeight, direction: .convex, side: .top)
    }
    
    @IBAction func didPressCloseButton(_ sender: UIButton) {
        self.close()
    }
    
    @IBAction func didPressFavoriteButton(_ sender: UIButton) {
        guard let product = self.product else { return }
        self.favoriteButton.alpha = 0.0
        let activity = UIActivityIndicatorView(activityIndicatorStyle: .white)
        activity.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(activity)
        activity.centerXAnchor.constraint(equalTo: self.favoriteButton.centerXAnchor).isActive = true
        activity.centerYAnchor.constraint(equalTo: self.favoriteButton.centerYAnchor).isActive = true
        activity.startAnimating()
        FavoritesStore.instance.addNewFavorite(product) { (syncState) in
            if let complete = syncState?.isDone(), complete == true {
                DispatchQueue.main.async {
                    activity.stopAnimating()
                    activity.removeFromSuperview()
                    self.favoriteButton.alpha = 1.0
                }
            }
        }
    }
    
    @IBAction func didPressAddToCartButton(_ sender: UIButton) {
        let activity = ActivityIndicatorView(frame: .zero)
        activity.showIn(self.view)
        activity.startAnimating()
        LocalCartStore.instance.commitToCart { (completedSuccessfully) in
            DispatchQueue.main.async {
                if completedSuccessfully {
                    self.close()
                } else {
                    let alert = UIAlertController(title: "Error", message: "Could not add items to cart, please verify your selections and try again.", preferredStyle: .alert)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func didPressCancelButton(_ sender: UIButton) {
        self.close()
    }
    
    fileprivate func close() {
        self.dismiss(animated: true) {
            if let c = self.dismissCompletion {
                c()
            }
        }
    }
    
    fileprivate func updateProductConfiguration(_ option:ProductOption, quantity:Int) {
        let selectedOption = LocalProductOption(product: option, quantity: quantity)
        LocalCartStore.instance.updateInProgressItem(selectedOption)
    }
}

extension ProductConfigureViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.productFamilies.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = self.attributeTableView.separatorColor
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.5
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as! ProductConfigureTableViewCell
        var controlStyle: ProductConfigureCellControlType = .unknown
        
        let family = self.productFamilies[indexPath.row]
        cell.name = family.familyName
        
        // todo - create object in platform to hold
        var iconName = "https://s3-us-west-2.amazonaws.com/sf-ios-barista-dev/productfamilies/"
        let familyName:String? = family.familyName.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .stringByAddingPercentEncodingForURL()
        if let name = familyName {
            iconName.append(name)
            iconName.append(".png")
            cell.imageURL = iconName
        }
        
        switch family.type {
        case .integer:
            controlStyle = .increment
            if let option = family.options.first {
                cell.minValue = option.minQuantity
                cell.maxValue = option.maxQuantity
                cell.currentValue = option.defaultQuantity
            }
        case .slider:
            let labels:[String] = family.options.map({ return $0.productName ?? ""})
            controlStyle = .slider
            cell.sliderLabels = labels
            cell.maxValue = labels.count
        case .picklist, .multiselect:
            let items:[String] = family.options.map({ return $0.productName ?? ""})
            controlStyle = .list
            cell.listItems = items
        }
        cell.controlStyle = controlStyle

        cell.controlClosure = { (value) in
            print("updated value to: \(value)")
            // todo update value on order item
            var option:ProductOption!
            if family.type == .integer {
                option = family.options.first!
            } else {
                option = family.options[value]
            }
            self.updateProductConfiguration(option, quantity: value)
        }
        cell.pickListClosure = { (index, name) in
            print("selected list item: \(name) at index: \(index)")
            // todo update value on order item
            // be sure to match index and name in case an item has a nil name
            let option = family.options[index]
            if let optionName = option.productName, optionName == name, let quantity = option.defaultQuantity {
                self.updateProductConfiguration(option, quantity: quantity)
            }
        }
        return cell
    }
}
