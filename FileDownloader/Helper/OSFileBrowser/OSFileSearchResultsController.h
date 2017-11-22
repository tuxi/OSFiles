//
//  OSFileSearchResultsController.h
//  FileBrowser
//
//  Created by Swae on 2017/11/20.
//  Copyright © 2017年 xiaoyuan. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class OSFileAttributeItem;

@interface OSFileSearchResultsController : UICollectionViewController <UISearchResultsUpdating>

// 存放搜索列表中显示数据的数组
@property (nonatomic, strong) NSMutableArray<OSFileAttributeItem *> *arrayOfSeachResults;
@property (nonatomic, strong) NSArray<OSFileAttributeItem *> *files;
@property (nonatomic, weak) UISearchController *searchController;

- (instancetype)initWithCollectionViewLayout:(nullable UICollectionViewLayout *)layout;

@end

NS_ASSUME_NONNULL_END
