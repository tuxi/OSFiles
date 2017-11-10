//
//  OSFileCollectionViewFlowLayout.h
//  FileBrowser
//
//  Created by xiaoyuan on 05/08/2014.
//  Copyright © 2014 xiaoyuan. All rights reserved.
//

@import UIKit;

@interface OSFileCollectionViewFlowLayout : UICollectionViewFlowLayout

@property (nonatomic, assign) IBInspectable UICollectionViewScrollDirection scrollDirection;
/// 每行item的个数
@property (nonatomic, assign) IBInspectable NSUInteger lineItemCount;
/// item之间的间距
@property (nonatomic, assign) IBInspectable CGFloat itemSpacing;
/// 行间距
@property (nonatomic, assign) IBInspectable CGFloat lineSpacing;
@property (nonatomic, assign) IBInspectable BOOL sectionsStartOnNewLine;
/// 行的宽高，默认设置此属性后，宽和高度相同
@property (nonatomic, assign) IBInspectable CGFloat lineSize;
/// 设置行高的约束：高度=lineSize*lineMultiplier
@property (nonatomic, assign) IBInspectable CGFloat lineMultiplier;
/// 设置行高的约束：高度=lineSize+lineExtension，和lineMultiplier只会是最后一个设置的有效
@property (nonatomic, assign) IBInspectable CGFloat lineExtension;

@end

