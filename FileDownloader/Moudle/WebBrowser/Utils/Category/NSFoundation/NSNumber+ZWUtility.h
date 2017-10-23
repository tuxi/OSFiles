//
//  NSNumber+ZWUtility.h
//  WebBrowser
//
//  Created by Null on 2017/1/9.
//  Copyright © 2017年 Null. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNumber (ZWUtility)

- (CGFloat)CGFloatValue;
- (id)initWithCGFloat:(CGFloat)value;
+ (NSNumber *)numberWithCGFloat:(CGFloat)value;

@end
