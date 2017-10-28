//
//  AutoTimer.h
//  Boobuz
//
//  Created by xiaoyuan on 17/5/16.
//  Copyright © 2017年 erlinyou.com. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, AutoTimerActionOption) {
//    AutoTimerActionOptionDefault = 0,
    AutoTimerActionOptionGiveUp,
    /// 放弃同一个timer重复触发启动的任务，防止定时器执行时重复调用startTimerWithIdentifier:导致定时器被重复执行，当重复调用此方法时，定时器会停止执行，待最后一次触发后，再继续执行之前的任务
    AutoTimerActionOptionMerge/// 将同一个timer之前的任务合并到新的任务中，当定时器执行时，重复触发startTimerWithIdentifier:会将之前的任务合并，待最后一次触发时，会一次执行之前所有触发的任务
};


@interface AutoTimer : NSObject

////@property (copy) NSDate *fireDate;
///// 定时器默认开始执行的时间为启动时间+定时器执行的间隔时间
//@property (nonatomic, assign) NSTimeInterval fireTimeInterval;



/// 开启一个定时器 定时器不会立即执行 当执行期间触发开始时AutoTimerActionOptionGiveUp
/// @param interval        timer执行的时间间隔
/// @param block           定时器执行的事件
+ (void)startWithTimeInterval:(NSTimeInterval)interval block:(void (^)(void))block;
+ (void)cancel;


/// 开启一个定时器
/// @param timerIdentifier 当前timer的key，每一个timer的标识
/// @param fireTime 定时器多少秒后开始执行
/// @param interval        timer执行的时间间隔
/// @param queue           执行timer的队列，传入nil将开启子线程执行
/// @param repeats         是否重复执行
/// @param option          当多次重复开始同一个timer时的操作选项(目前提供将之前的任务废除或合并的选项)。
/// @param block           定时器执行的事件
+ (void)startTimerWithIdentifier:(NSString *)timerIdentifier
                        fireTime:(NSTimeInterval)fireTime
                    timeInterval:(NSTimeInterval)interval
                           queue:(dispatch_queue_t)queue
                         repeats:(BOOL)repeats
                    actionOption:(AutoTimerActionOption)option
                           block:(void (^)(void))block;


/// 取消一个定时器
/// @param timerIdentifier 定时器的唯一标识
+ (void)cancel:(NSString *)timerIdentifier;


+ (BOOL)existTimer:(NSString *)timerKey;

@end

