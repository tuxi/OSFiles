//
//  UITableView+NoDataPlaceholderExtend.h
//  MVVMDemo
//
//  Created by Ossey on 2017/5/30.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "UIScrollView+NoDataPlaceholder.h"

@interface UITableView (NoDataPlaceholderExtend) <NoDataPlaceholderDataSource, NoDataPlaceholderDelegate>

@property (nonatomic, strong) NSAttributedString *noDataPlaceholderTitleAttributedString;
@property (nonatomic, strong) NSAttributedString *noDataPlaceholderDetailAttributedString;
@property (nonatomic, strong) NSAttributedString *noDataPlaceholderReloadbuttonAttributedString;
@property (nonatomic, copy) void (^reloadButtonClickBlock)();
@property (nonatomic, strong) UIImage *noDataPlaceholderLoadingImage;
@property (nonatomic, strong) UIImage *noDataPlaceholderNotLoadingImage;

/// 使用NoDataPlaceholder
- (void)usingNoDataPlaceholder;


@end
