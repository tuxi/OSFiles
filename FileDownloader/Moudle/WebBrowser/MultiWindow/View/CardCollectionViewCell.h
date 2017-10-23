//
//  CardCollectionViewCell.h
//  WebBrowser
//
//  Created by Null on 2016/12/20.
//  Copyright © 2016年 Null. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CardMainView;
@class WebModel;

typedef void(^CloseBlock)(NSIndexPath *indexPath);

@interface CardCollectionViewCell : UICollectionViewCell

@property (nonatomic, copy) CloseBlock closeBlock;
@property (nonatomic, weak) UICollectionView *collectionView;

- (void)updateWithWebModel:(WebModel *)webModel;

@end
