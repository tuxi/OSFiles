//
//  UIButton+ClickBlock.h
//
//
//  Created by mofeini on 16/10/21.
//  Copyright © 2016年 sey. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ClickButtonBlock)(UIButton *btn);

@interface UIButton (ClickBlock)

/** 按钮重复点击的时间间隔,以秒为单位 **/
@property NSTimeInterval repeatEventInterval;

/**
 将selctor转换为block回调
 调用这段代码时，直接在block中执行点击事件即可
 注意: 外界调用时，要防止循环引用，但是外界使用btn参数不会产生循环引用
 */
- (void)xy_buttonClickBlock:(ClickButtonBlock)block;

/**
 作用:将selctor转换为block回调
 先返回一个UIButton对象，当点击按钮时，再将按钮的点击事件进行回调
 clickBtnCallBack: 点击按钮时回调执行
 注意: 外界调用时，要防止循环引用哦!
 */
+ (instancetype)xy_button:(ClickButtonBlock)btn buttonClickCallBack:(ClickButtonBlock)callBack;

/**
 作用:将selctor转换为block回调
 根据传入的UIButtonType创建按钮
 先返回一个UIButton对象，当点击按钮时，再将按钮的点击事件进行回调
 clickBtnCallBack: 点击按钮时回调执行
 注意: 外界调用时，要防止循环引用哦!
 */
+ (instancetype)xy_buttonWithType:(UIButtonType)type buttonCallBack:(ClickButtonBlock)btn buttonClickCallBack:(ClickButtonBlock)callBack;

/**
 只回调创建的按钮
 */
+ (instancetype)xy_button:(ClickButtonBlock)btn;
@end
