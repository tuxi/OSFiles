//
//  UITextField+XYExtensions.h
//  FileBrowser
//
//  Created by xiaoyuan on 08/12/2017.
//  Copyright © 2017 xiaoyuan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextField (XYExtensions)

- (NSInteger)currentOffset;
- (void)makeOffset:(NSInteger)offset;
- (void)makeOffsetFromBeginning:(NSInteger)offset;

@end
