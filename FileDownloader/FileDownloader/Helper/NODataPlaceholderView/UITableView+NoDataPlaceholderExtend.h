//
//  UITableView+NoDataPlaceholderExtend.h
//  MVVMDemo
//
//  Created by Ossey on 2017/5/30.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "UIScrollView+NoDataPlaceholder.h"

@interface UITableView (NoDataPlaceholderExtend) <NoDataPlaceholderDataSource, NoDataPlaceholderDelegate>

@property (nonatomic, copy) void (^reloadButtonClickBlock)();

@end
