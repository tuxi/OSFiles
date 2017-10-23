//
//  UIImage+ZWUtility.h
//  WebBrowser
//
//  Created by Null on 2017/1/10.
//  Copyright © 2017年 Null. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ZWUtility)

- (UIImage *)getCornerImageWithFrame:(CGRect)rect cornerRadius:(CGFloat)cornerRadius text:(NSString *)text atPoint:(CGPoint)point;

@end
