//
//  OSDrawerAnimation.h
//  OSDrawerControllerSample
//
//  Created by Swae on 2017/11/15.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, OSDrawerSide) {
    OSDrawerSideNone, // 未打开
    OSDrawerSideLeft, // 左面
    OSDrawerSideRight // 右面
};

@protocol OSDrawerAnimation <NSObject>

/// 实现此方法，打开应该显示的side
/// @param drawerSide 要打开的抽屉侧面
/// @param sideView   要打开的抽屉侧面的控制器view
/// @param centerView 中心视图
/// @param animated   是否需要动画
/// @param completion 显示side后的回调
- (void)presentationWithSide:(OSDrawerSide)drawerSide
                    sideView:(UIView *)sideView
                  centerView:(UIView *)centerView
                    animated:(BOOL)animated
                  completion:(void(^)(BOOL finished))completion;

/// 实现此方法，关闭side
/// @param drawerSide 要关闭的抽屉侧面
/// @param sideView   要关闭的抽屉侧面的控制器view
/// @param centerView 中心视图
/// @param animated   是否需要动画
/// @param completion 关闭side后的回调
- (void)dismissWithSide:(OSDrawerSide)drawerSide
               sideView:(UIView *)sideView
             centerView:(UIView *)centerView
               animated:(BOOL)animated
             completion:(void(^)(BOOL finished))completion;

/// 打开的侧面即将旋转时调用，需要在此时做一些适配
/// @param drawerSide 打开的侧面
/// @param sideView 打开的侧面的视图
/// @param centerView 中心视图
- (void)willRotateOpenDrawerWithOpenSide:(OSDrawerSide)drawerSide
                                sideView:(UIView *)sideView
                              centerView:(UIView *)centerView;

/// 打开的侧面已经旋转时调用，需要在此时做一些适配
/// @param drawerSide 打开的侧面
/// @param sideView 打开的侧面的视图
/// @param centerView 中心视图
- (void)didRotateOpenDrawerWithOpenSide:(OSDrawerSide)drawerSide
                               sideView:(UIView *)sideView
                             centerView:(UIView *)centerView;

@end

@interface OSDrawerAnimation : NSObject <OSDrawerAnimation>

@property (nonatomic, assign) NSTimeInterval animationDuration;
@property (nonatomic, assign) NSTimeInterval animationDelay;
@property (nonatomic, assign) CGFloat springDamping;
@property (nonatomic, assign) CGFloat initialSpringVelocity;

@end
