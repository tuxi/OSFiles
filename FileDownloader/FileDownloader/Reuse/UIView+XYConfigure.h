//
//  UIView+XYConfigure.h
//  MVVMDemo
//
//  Created by Ossey on 17/2/10.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XYViewModelProtocol.h"

@interface UIView (XYConfigure)

/// 根据model配置view, 设置view的内容
- (void)xy_configViewByModel:(id)model;

/// 根据viewModel配置view，设置view的内容
- (void)xy_configViewByViewModel:(id<XYViewModelProtocol>)vm;

@end
