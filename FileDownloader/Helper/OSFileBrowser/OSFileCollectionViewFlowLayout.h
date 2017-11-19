//
//  OSFileCollectionViewFlowLayout.h
//  FileBrowser
//
//  Created by xiaoyuan on 05/08/2014.
//  Copyright © 2014 xiaoyuan. All rights reserved.
//

@import UIKit;

FOUNDATION_EXPORT NSNotificationName const OSFileCollectionLayoutStyleDidChangeNotification;

typedef NS_ENUM(NSInteger, OSFileCollectionLayoutStyle) {
    OSFileCollectionLayoutStyleMultipleItemOnLine, // 一行可以有多个item
    OSFileCollectionLayoutStyleSingleItemOnLine, // 一行只有一个item
};

@interface OSFileCollectionViewFlowLayout : UICollectionViewFlowLayout

@property (nonatomic, assign) IBInspectable UICollectionViewScrollDirection scrollDirection;
/// 每行item的个数
@property (nonatomic, assign) IBInspectable NSUInteger lineItemCount;
/// item之间的间距
@property (nonatomic, assign) IBInspectable CGFloat itemSpacing;
/// 行间距
@property (nonatomic, assign) IBInspectable CGFloat lineSpacing;
/// 是否从新的一行开始
@property (nonatomic, assign) IBInspectable BOOL sectionsStartOnNewLine;
/// 行的宽高，默认设置此属性后，宽和高度相同
@property (nonatomic, assign) IBInspectable CGFloat lineSize;
/// 设置行高的约束：高度=lineSize*lineMultiplier
@property (nonatomic, assign) IBInspectable CGFloat lineMultiplier;
/// 设置行高的约束：高度=lineSize+lineExtension，和lineMultiplier只会是最后一个设置的有效
@property (nonatomic, assign) IBInspectable CGFloat lineExtension;
/// 设置collectionView 头部的尺寸，自定义UICollectionViewFlowLayout后，设置headerReferenceSize无效，并且导致不走代理方法
/// 头部视图的尺寸，当为{0,0}时没有头部视图, 不需要再headerReferenceSize了
@property (nonatomic, assign) IBInspectable CGSize headerSize;

/// 记录每行是否只有单个item，用来布局cell的，这是控制全局collectionView cell的显示
@property (nonatomic, assign, class) OSFileCollectionLayoutStyle collectionLayoutStyle;

@end

