//
//  UIButton+ClickBlock.m
//  
//
//  Created by mofeini on 16/10/21.
//  Copyright © 2016年 sey. All rights reserved.
//

#import "UIButton+ClickBlock.h"
#import <objc/message.h>

const char *buttonClickKey         = "buttonClickKey";
const char *buttonClickCallBackKey  = "buttonClickCallBackKey";
const char *repeatEventIntervalKey   = "repeatEventIntervalKey";
const char *previousClickTimeKey      = "previousClickTimeKey";

@interface UIButton ()

/** 保存1970年到现在的时间(timeIntervalSince1970)，时间只会越来越大 */
@property NSTimeInterval previousClickTime;

@end

@implementation UIButton (ClickBlock)

#pragma mark - 将按钮的响应事件转换为block回调
- (void)xy_buttonClickBlock:(ClickButtonBlock)block {
    
    [self addTarget:self action:@selector(handleClick) forControlEvents:UIControlEventTouchUpInside];
    
    objc_setAssociatedObject(self, buttonClickKey, block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

// 执行按钮点击事情的回调
- (void)handleClick {
    
    // 取出key中保存的block，如果有就执行block，这样就会将外界调用(void)clickBlock:(void (^)())clickBlock传进来的值在block中执行
    void(^block)(UIButton *) = (ClickButtonBlock)objc_getAssociatedObject(self, buttonClickKey);
    
    if (block) {
        block(self);
    }
    
   
}

- (instancetype)initWithButtonType:(UIButtonType)type buttonCallBack:(ClickButtonBlock)btn buttonClickCallBack:(ClickButtonBlock)callBack {
    
    if (self = [super init]) {
        
        [self addTarget:self action:@selector(handleClickCallBack) forControlEvents:UIControlEventTouchUpInside];
        
        objc_setAssociatedObject(self, buttonClickCallBackKey, callBack, OBJC_ASSOCIATION_COPY_NONATOMIC);
        
        [self setValue:@(type) forKeyPath:@"buttonType"];
        
        if (btn) {
            
            btn(self);
        }
    }
    return self;
}

+ (instancetype)xy_button:(ClickButtonBlock)btn {
    
    return [[self alloc] initWithButtonType:0 buttonCallBack:btn buttonClickCallBack:nil];
    
}

+ (instancetype)xy_button:(ClickButtonBlock)btn buttonClickCallBack:(ClickButtonBlock)callBack {
    
    return [[self alloc] initWithButtonType:0 buttonCallBack:btn buttonClickCallBack:callBack];
    
}

+ (instancetype)xy_buttonWithType:(UIButtonType)type buttonCallBack:(ClickButtonBlock)btn buttonClickCallBack:(ClickButtonBlock)callBack {

    return [[self alloc] initWithButtonType:type buttonCallBack:btn buttonClickCallBack:callBack];
}

// 点击按钮的时候调用
- (void)handleClickCallBack {
    
    // 取出保存的block属性
    void(^block)(UIButton *) = (ClickButtonBlock)objc_getAssociatedObject(self, buttonClickCallBackKey);
    
    if (block) {
        block(self);
    }
}


#pragma mark - 控制按钮重复点击的时间间隔
+ (void)load {
    
    // 交换方法
    Method sendAction = class_getInstanceMethod([self class], @selector(sendAction:to:forEvent:));
    Method xy_SendAction = class_getInstanceMethod([self class], @selector(xy_sendAction:to:forEvent:));
    
    method_exchangeImplementations(xy_SendAction, sendAction);
}

// 重写，为了防止在tabBarController下点击tabBarItem时报错
- (void)sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {

    [super sendAction:action to:target forEvent:event];
}

- (void)setRepeatEventInterval:(NSTimeInterval)repeatEventInterval {
    
    objc_setAssociatedObject(self, repeatEventIntervalKey, @(repeatEventInterval), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimeInterval)repeatEventInterval {
    
    NSTimeInterval repeatEventIn = (NSTimeInterval)[objc_getAssociatedObject(self, repeatEventIntervalKey) doubleValue];
    
    // 如果外界设置的重复点击的时间间隔大于0，就按照用户设置的去处理，如果用户设置的间隔时间小于或等于0，就按照无间隔处理
    if (repeatEventIn >= 0) {
        return repeatEventIn;
    }
    
    return 0.0;
}

- (void)setPreviousClickTime:(NSTimeInterval)previousClickTime {
    
    objc_setAssociatedObject(self, previousClickTimeKey, @(previousClickTime), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (NSTimeInterval)previousClickTime {
    
    NSTimeInterval previousEventTime = [objc_getAssociatedObject(self, previousClickTimeKey) doubleValue];
    if (previousEventTime != 0) {
        
        return previousEventTime;
    }
    
    return 1.0;
}



- (void)xy_sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
    
    NSTimeInterval time = [[[NSDate alloc] init] timeIntervalSince1970];
    if (time - self.previousClickTime < self.repeatEventInterval) {
        return;
    }
    
    // 如果间隔时间大于0
    if (self.repeatEventInterval > 0) {
        self.previousClickTime = [[[NSDate alloc] init] timeIntervalSince1970];
    }
    
    // 已在load中与系统的sendAction:to:forEvent:方法交换方法实现，所以下面调用的还是系统的方法
    [self xy_sendAction:action to:target forEvent:event];
}

@end
