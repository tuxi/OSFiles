//
//  OSFileCollectionViewCell.h
//  FileBrowser
//
//  Created by xiaoyuan on 05/08/2014.
//  Copyright © 2014 xiaoyuan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OSFileAttributeItem, OSFileCollectionViewCell;

@protocol OSFileCollectionViewCellDelegate <NSObject>

@optional
- (void)fileCollectionViewCell:(OSFileCollectionViewCell *)cell fileAttributeChange:(OSFileAttributeItem *)fileModel;
- (void)fileCollectionViewCell:(OSFileCollectionViewCell *)cell needCopyFile:(OSFileAttributeItem *)fileModel;
- (void)fileCollectionViewCell:(OSFileCollectionViewCell *)cell needDeleteFile:(OSFileAttributeItem *)fileModel;
- (void)fileCollectionViewCell:(OSFileCollectionViewCell *)cell didMarkupFile:(OSFileAttributeItem *)fileModel;

@end

@interface OSFileCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) OSFileAttributeItem *fileModel;
@property (nonatomic, weak) id<OSFileCollectionViewCellDelegate> delegate;

/// 重新布局
- (void)invalidateConstraints;

@end

