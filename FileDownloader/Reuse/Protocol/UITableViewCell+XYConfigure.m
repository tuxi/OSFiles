//
//  UITableViewCell+XYConfigure.m
//  MVVMDemo
//
//  Created by mofeini on 17/2/10.
//  Copyright © 2017年 com.test.demo. All rights reserved.
//

#import "UITableViewCell+XYConfigure.h"

@implementation UITableViewCell (XYConfigure)

#pragma mark - private
+ (UINib *)nibWithIdentifier:(NSString *)identifier {
    return [UINib nibWithNibName:identifier bundle:nil];
}

#pragma mark - public 
+ (void)xy_registerTableViewCell:(UITableView *)tableView nibIdentifier:(NSString *)identifier {
    [tableView registerNib:[self nibWithIdentifier:identifier] forCellReuseIdentifier:identifier];
}

+ (void)xy_registerTableViewCell:(UITableView *)tableView classIdentifier:(NSString *)identifier {
    [tableView registerClass:[self class] forCellReuseIdentifier:identifier];
}

#pragma mark - Rewrite these func in SubClass !
- (void)xy_configCellByModel:(id)model indexPath:(NSIndexPath *)indexPath {
    /// Rewrite these func in SubClass !
}

- (void)xy_configCellByViewModel:(id<XYViewModelProtocol>)viewModel indexPath:(NSIndexPath *)indexPath {
    /// Rewrite these func in SubClass !
}

- (CGFloat)xy_getCellHeightWithModel:(id)model indexPath:(NSIndexPath *)indexPath {
    /// Rewrite these func in SubClass !
    if (!model) {
        return 0;     // 没有数据时cell高度为0
    } else {
        return 44.0;  // 默认cell高度44
    }
}

@end
