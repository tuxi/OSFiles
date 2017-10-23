//
//  UIColor+ZWUtility.m
//  iOSSampleCode
//
//  Created by Null on 16/7/4.
//  Copyright © 2016年 Null. All rights reserved.
//

#import "UIColor+ZWUtility.h"

@implementation UIColor (ZWUtility)

+ (UIColor *)randomColor
{
    CGFloat hue = (arc4random() % 100) / 100.0f;
    CGFloat saturation = (arc4random() % 100) / 100.0f;
    CGFloat brightness = (arc4random() % 100) / 100.0f;
    
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1.0f];
}

@end
