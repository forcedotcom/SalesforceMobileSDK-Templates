 //
//  OrderMainCollectionViewLayout.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/6/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import UIKit

class OrderMainCollectionViewLayout: UICollectionViewLayout {
    var itemSpacing: CGFloat = 0.0
    var horizontalCellCount: Int = 3
    fileprivate var verticalSize: CGFloat = 0.0
    fileprivate var attributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    
    override func prepare() {
        self.attributes.removeAll()
        for i in (0..<self.collectionView!.numberOfItems(inSection: 0)) {
            let indexPath = IndexPath(row: i, section: 0)
            let attribs = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attribs.frame = self.frameForItem(indexPath)
            self.attributes[indexPath] = attribs
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var allAttribs: [UICollectionViewLayoutAttributes] = []
        for (_, attributes) in self.attributes {
            if rect.intersects(attributes.frame) {
                allAttribs.append(attributes)
            }
        }
        return allAttribs
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return self.attributes[indexPath]
    }
    
    func frameForItem(_ atIndexPath:IndexPath) -> CGRect {
        var xSize: CGFloat = 0.0
        var ySize: CGFloat = 0.0
        var xPos: CGFloat = 0.0
        var yPos: CGFloat = 0.0
        xSize = self.collectionView!.frame.size.width / CGFloat(self.horizontalCellCount)
        let spaceMinus = CGFloat(self.horizontalCellCount + 1) / CGFloat(self.horizontalCellCount)
        xSize -= self.itemSpacing * spaceMinus
        xSize = floor(xSize)
        ySize = xSize
        
        xPos = floor(xSize * (0 + CGFloat(atIndexPath.row % self.horizontalCellCount)) + (self.itemSpacing * CGFloat(atIndexPath.row % self.horizontalCellCount))) + self.itemSpacing
        yPos = floor(ySize * CGFloat(atIndexPath.row / self.horizontalCellCount) + (self.itemSpacing * CGFloat(atIndexPath.row / self.horizontalCellCount))) + self.itemSpacing
        
        let rect = CGRect(x: xPos, y: yPos, width: xSize, height: ySize)
        self.verticalSize = ySize
        return rect
    }
    
    override var collectionViewContentSize: CGSize {
        let itemCount = self.collectionView!.numberOfItems(inSection: 0)
        let rowCount = ceil(CGFloat(itemCount) / CGFloat(self.horizontalCellCount))
        let height = self.verticalSize * rowCount
        return CGSize(width: self.collectionView!.frame.size.width, height: height)
    }
}
