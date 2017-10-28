//
//  AutoTimer.m
//  Boobuz
//
//  Created by xiaoyuan on 17/5/16.
//  Copyright © 2017年 erlinyou.com. All rights reserved.
//

#import "AutoTimer.h"
#import <objc/runtime.h>
#import "NSString+MD5.h"

static NSString * const _TimerKey = @"timer";
static NSString * const _ActionKey = @"Action";

@implementation AutoTimer {
    
    NSMutableDictionary<NSString *, NSMutableDictionary *> *_timerDictionary;
}


+ (AutoTimer *)sharedInstance {
    
    static AutoTimer *_timer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _timer = [AutoTimer new];
       
    });
    
    return _timer;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
         _timerDictionary = [NSMutableDictionary dictionaryWithCapacity:0];
    }
    return self;
}

+ (void)startWithTimeInterval:(NSTimeInterval)interval block:(void (^)(void))block {
    
    [self startTimerWithIdentifier:[[AutoTimer sharedInstance].description MD5Hash] fireTime:interval timeInterval:interval queue:nil repeats:YES actionOption:AutoTimerActionOptionGiveUp block:block];
}


+ (void)startTimerWithIdentifier:(NSString *)timerIdentifier
                        fireTime:(NSTimeInterval)fireTime
                    timeInterval:(NSTimeInterval)interval
                           queue:(dispatch_queue_t)queue
                         repeats:(BOOL)repeats
                    actionOption:(AutoTimerActionOption)option
                           block:(void (^)(void))block {
    
    if (nil == timerIdentifier) {
        return;
    }
    
    
    if (nil == queue) {
        queue = dispatch_queue_create("com.ossey.AutoTimer.queue", DISPATCH_QUEUE_CONCURRENT);
        
    }
    AutoTimer *instace = [AutoTimer sharedInstance];
    
    if (!instace->_timerDictionary) {
        instace->_timerDictionary = [NSMutableDictionary dictionaryWithCapacity:0];
    }
    NSMutableDictionary *timerDict = instace->_timerDictionary[_TimerKey];
    NSMutableDictionary *actionDict = instace->_timerDictionary[_ActionKey];
    if (!timerDict) {
        timerDict = [NSMutableDictionary dictionaryWithCapacity:0];
        [instace->_timerDictionary setObject:timerDict forKey:_TimerKey];
    }
    if (!actionDict) {
        actionDict = [NSMutableDictionary dictionaryWithCapacity:0];
        [instace->_timerDictionary setObject:actionDict forKey:_ActionKey];
    }
    
    dispatch_source_t timer = [timerDict objectForKey:timerIdentifier];
    if (!timer) {
        timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        dispatch_resume(timer);
        [timerDict setObject:timer forKey:timerIdentifier];
    }
    if (fireTime < 0.0) {
        fireTime = 0.0;
    }
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, fireTime * NSEC_PER_SEC), interval * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
    
    
    if (option == AutoTimerActionOptionGiveUp) {
        
        // 移除之前的定时器执行的事件
        if (actionDict.count) {
            [actionDict removeObjectForKey:timerIdentifier];
        }
        
        dispatch_source_set_event_handler(timer, ^{ @autoreleasepool {
            if (block) {
                block();
            }
            
            if (!repeats) {
                [AutoTimer cancel:timerIdentifier];
            }
        }});
    } else if (option == AutoTimerActionOptionMerge) {
        
        // 保存定时器执行的事件
        [instace saveActionBlock:block forTimerIdentifier:timerIdentifier];
        
        dispatch_source_set_event_handler(timer, ^{ @autoreleasepool {
            NSMutableArray *actionArray = [actionDict objectForKey:timerIdentifier];
            [actionArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                void (^block)(void) = obj;
                if (block) {
                    block();
                }
            }];
            
            [actionDict removeObjectForKey:timerIdentifier];
            
            if (!repeats) {
                [AutoTimer cancel:timerIdentifier];
            }
        }});
    }
    
}

+ (void)cancel:(NSString *)timerKey {
    
    if (nil == timerKey) {
        return;
    }
    
    AutoTimer *instace = [AutoTimer sharedInstance];
    NSMutableDictionary *timerDict = instace->_timerDictionary[_TimerKey];
    NSMutableDictionary *actionDict = instace->_timerDictionary[_ActionKey];
    
    dispatch_source_t timer = [timerDict objectForKey:timerKey];
    
    if (!timer) {
        return;
    }
    
    [timerDict removeObjectForKey:timerKey];
    dispatch_source_cancel(timer);
    timer = nil;
    
    [actionDict removeObjectForKey:timerKey];
    
    [instace->_timerDictionary removeAllObjects];
    instace->_timerDictionary = nil;
    
}

+ (void)cancel {
    
    [self cancel:[[AutoTimer sharedInstance].description MD5Hash]];
}

+ (BOOL)existTimer:(NSString *)timerKey {
    return [[AutoTimer sharedInstance]->_timerDictionary objectForKey:timerKey];
}

- (void)saveActionBlock:(void (^)(void))block forTimerIdentifier:(NSString *)timerIdentifier {
    if (nil == timerIdentifier) {
        return;
    }
    
    if (!_timerDictionary) {
        _timerDictionary = [NSMutableDictionary dictionaryWithCapacity:0];
    }
    NSMutableDictionary *timerDict = _timerDictionary[_TimerKey];
    NSMutableDictionary *actionDict = _timerDictionary[_ActionKey];
    if (!timerDict) {
        timerDict = [NSMutableDictionary dictionaryWithCapacity:0];
        [_timerDictionary setObject:timerDict forKey:_TimerKey];
    }
    if (!actionDict) {
        actionDict = [NSMutableDictionary dictionaryWithCapacity:0];
        [_timerDictionary setObject:actionDict forKey:_ActionKey];
    }
    
    id actionArray = [actionDict objectForKey:timerIdentifier];
    
    if (actionArray && [actionArray isKindOfClass:[NSMutableArray class]]) {
        [(NSMutableArray *)actionArray addObject:block];
    }else {
        NSMutableArray *array = [NSMutableArray arrayWithObject:block];
        [actionDict setObject:array forKey:timerIdentifier];
    }
}


//- (dispatch_time_t)fireTimer {
////    uint64_t delay = (uint64_t)([self.fireDate timeIntervalSinceNow] * NSEC_PER_SEC);
////    dispatch_time_t fireTime = dispatch_time(DISPATCH_TIME_NOW, delay);
////    return fireTime;
//
//    uint64_t intervalTime = self.fireTimeInterval * NSEC_PER_SEC;
//    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, intervalTime);
//
//    return startTime;
//}

@end
