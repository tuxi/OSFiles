//
//  XYViewManagerProtocol.h
//  MVVMDemo
//
//  Created by Ossey on 17/2/9.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 *  将自己的信息返回给ViewManger的block
 */
typedef void (^ViewMangerInfosBlock)( );

@protocol XYViewManagerProtocol <NSObject>

@optional

/// 通知
- (void)xy_notify;

/**
 *  设置控制器的子视图的管理者为self
 *
 * @param   superView  一般指superView所在的控制器的根view
 */
- (void)xy_viewManagerWithSuperView:(UIView *)superView;

/**
 *  设置subView的管理者为self
 *
 * @param   subView 管理的subview
 */
- (void)xy_viewManagerWithSubView:(UIView *)subView;

/**
 *  设置添加subView的事件
 *
 * @param   subView  管理的subView
 * @param   info  附带信息 用于区分回调
 */
- (void)xy_viewManagerWithHandleOfSubView:(UIView *)subView info:(NSString *)info;

/**
 *  返回viewManager所管理的视图
 * @return  view
 */
- (__kindof UIView *)xy_viewManagerOfSubView;

/**
 *  得到其他viewManager所管理的subview 用户自己内部
 *
 * @param   viewInfos  其他的subViews
 */
- (void)xy_viewManagerWithOtherSubviews:(NSDictionary *)viewInfos;

/**
 *  需要重新布局subView时，更新subview的frame或约束
 *
 * @param   updateBlock  布局更新完成后的回调
 */
- (void)xy_viewManagerWithLayoutSubviews:(void (^)())updateBlock;

/**
 *  使子视图更新到最新的布局约束或frame
 */
- (void)xy_viewManagerWithUpdateLayoutSubviews;

/**
 *  将模型数据传递给viewManager
 */
- (void)xy_viewManagerWithModel:(NSDictionary *(^)())block;

@end
