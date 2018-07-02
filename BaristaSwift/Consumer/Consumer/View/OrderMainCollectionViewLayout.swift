/*
  OrderMainCollectionViewLayout.swift
  Consumer

  Created by Nicholas McDonald on 2/6/18.

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
