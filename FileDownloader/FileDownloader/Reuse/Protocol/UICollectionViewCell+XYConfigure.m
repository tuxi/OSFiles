//
//  UICollectionViewCell+XYConfigure.m
//  DevelopFramework
//
//  Created by mofeini on 17/2/10.
//  Copyright © 2017年 com.test.demo. All rights reserved.
//

#import "UICollectionViewCell+XYConfigure.h"

@implementation UICollectionViewCell (XYConfigure)

#pragma mark -- Private
+ (UINib *)nibWithIdentifier:(NSString *)identifier
{
    return [UINib nibWithNibName:identifier bundle:nil];
}

#pragma mark - Public
+ (void)xy_registerCollect:(UICollectionView *)collect
        nibIdentifier:(NSString *)identifier
{
    [collect registerNib:[self nibWithIdentifier:identifier] forCellWithReuseIdentifier:identifier];
}

+ (void)xy_registerCollect:(UICollectionView *)collect classIdentifier:(NSString *)identifier {
    [collect registerClass:[self class] forCellWithReuseIdentifier:identifier];
}

#pragma mark - Rewrite these func in SubClass !
- (void)xy_configureCellByModel:(id)model indexPath:(NSIndexPath *)indexPath
{
    // Rewrite this func in SubClass !
}

- (void)xy_configureCellByViewModel:(id<XYViewModelProtocol>)viewModel
                          indexPath:(NSIndexPath *)indexPath 
{
    // Rewrite this func in SubClass !
}

+ (CGFloat)xy_getCellHeightWithModel:(id)model indexPath:(NSIndexPath *)indexPath
{
    // Rewrite this func in SubClass if necessary
    if (!model) {
        return 0.0f ; // if obj is null .
    }
    return 44.0f ; // default cell height
}

@end
