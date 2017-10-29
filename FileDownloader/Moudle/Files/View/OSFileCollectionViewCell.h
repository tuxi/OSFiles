//
//  OSFileCollectionViewCell.h
//  FileDownloader
//
//  Created by Swae on 2017/10/29.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OSFileAttributeItem, OSFileCollectionViewCell;

@protocol OSFileCollectionViewCellDelegate <NSObject>

@optional
- (void)fileCollectionViewCell:(OSFileCollectionViewCell *)cell fileAttributeChange:(OSFileAttributeItem *)fileModel;
- (void)fileCollectionViewCell:(OSFileCollectionViewCell *)cell needCopyFile:(OSFileAttributeItem *)fileModel;

@end

@interface OSFileCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) OSFileAttributeItem *fileModel;
@property (nonatomic, weak) id<OSFileCollectionViewCellDelegate> delegate;

@end
