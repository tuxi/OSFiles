//
//  NSString+DateExtension.h
//
//
//  Created by Ossey on 16/8/10.
//  Copyright © 2016年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (DateExtension)

/**
 *  将时间戳转换为XXXX年XX月XX日
 *
 *  @param time 时间戳
 *
 *  @return 年：月：日
 */
+ (NSString *)formatYearMonthDay:(NSTimeInterval)time;

/**
 *  将时间转换为XX小时XX分XX秒
 *
 *  @param time 时间戳
 *
 *  @return 时：分：秒
 */
+ (NSString *)formatHourMinutesSecond:(NSTimeInterval)time;

/**
 *  将时间转换为XXXX年XX月XX分XX时XX分XX秒
 *
 *  @param time 时间戳
 *
 *  @return 年：月：日：时：分：秒
 */
+ (NSString *)formatYearMonthDayHourMinutesSecond:(NSTimeInterval)time;

@end
