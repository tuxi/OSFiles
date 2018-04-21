//
//  UITextField+OSRangeExtension.h
//  FileDownloader
//
//  Created by xiaoyuan on 31/10/2017.
//  Copyright © 2017 alpface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextField (OSRangeExtension)

/// 获取TextField当前光标位置
- (NSRange)selectedRange;
/// 设置TextField光标位置
- (void)setSelectedRange:(NSRange)range;

@end
