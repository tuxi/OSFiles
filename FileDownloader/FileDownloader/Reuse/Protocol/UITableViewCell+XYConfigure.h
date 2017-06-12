//
//  UITableViewCell+XYConfigure.h
//  MVVMDemo
//
//  Created by mofeini on 17/2/10.
//  Copyright © 2017年 com.test.demo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XYViewModelProtocol.h"

@interface UITableViewCell (XYConfigure)

/// 从nib文件中根据重用标识符注册UITableViewCell
+ (void)xy_registerTableViewCell:(UITableView *)tableView nibIdentifier:(NSString *)identifier;
/// 根据类名 注册UITableViewCell
+ (void)xy_registerTableViewCell:(UITableView *)tableView classIdentifier:(NSString *)identifier;

/// 根据model配置UITableViewCell，设置UITableViewCell的内容
- (void)xy_configCellByModel:(id)model indexPath:(NSIndexPath *)indexPath;
/// 根据viewModel配置UITableViewCell， 设置UITableViewCell的内容
- (void)xy_configCellByViewModel:(id<XYViewModelProtocol>)viewModel indexPath:(NSIndexPath *)indexPath;
/// 获取自定义对象cell的高度（已集成UITableView+FDTemplateLayoutCell， 现在创建的cell自动计算高度）
- (CGFloat)xy_getCellHeightWithModel:(id)model indexPath:(NSIndexPath *)indexPath;
@end
