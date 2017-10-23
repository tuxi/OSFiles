//
//  GestureProxy.h
//  WebBrowser
//
//  Created by Null on 2017/9/20.
//  Copyright © 2017年 Null. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GestureProxy : NSObject <UIGestureRecognizerDelegate>

@property (nonatomic, assign) CGPoint point;

- (instancetype)initWithCGPoint:(CGPoint)point;

@end
