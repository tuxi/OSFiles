//
//  XYMenuView.h
//  XYMenuView
//
//  Created by mofeini on 16/11/15.
//  Copyright © 2016年 com.test.demo. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, XYMenuViewBtnType) {
    XYMenuViewBtnTypeFastExport = 0, // 快速导出
    XYMenuViewBtnTypeHDExport,       // 高清导出
    XYMenuViewBtnTypeSuperClear,     // 高清导出
    XYMenuViewBtnTypeCancel,         // 取消
};

NS_ASSUME_NONNULL_BEGIN
@interface XYMenuView : UIView
/** 每个按钮的高度 **/
@property (nonatomic, assign) CGFloat itemHeight;
/** 分割符的颜色 **/
@property (nonatomic, strong) UIColor *separatorColor;

+ (instancetype)menuViewToSuperView:(UIView *)superView;
- (void)showMenuView;
- (void)dismissMenuView;
- (void)showMenuView:(nullable void(^)())block;
- (void)dismissMenuView:(nullable void(^)())block;

/**
 * @explain 点击menuView上不同类型按钮的事件回调
 *
 * type  不同类型按钮
 */
@property (nonatomic, copy) void (^menuViewClickBlock)(XYMenuViewBtnType type);
@end
NS_ASSUME_NONNULL_END
