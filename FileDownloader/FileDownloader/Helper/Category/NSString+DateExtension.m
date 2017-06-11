//
//  NSString+DateExtension.m
//  
//
//  Created by Ossey on 16/8/10.
//  Copyright © 2016年 Ossey. All rights reserved.
//

#import "NSString+DateExtension.h"
#import <objc/runtime.h>

@interface NSString ()

@property (nonatomic, strong, class) NSDateFormatter *dataFormat;

@end

@implementation NSString (DateExtension)

+ (NSDateFormatter *)dataFormat {
    NSDateFormatter *dataFormat = objc_getAssociatedObject(self, _cmd);
    if (dataFormat) {
        objc_setAssociatedObject(self, _cmd, dataFormat, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dataFormat;
}

+ (NSString *)formatYearMonthDay:(NSTimeInterval)time
{
    if (time < 0) return @"";
    
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    //注意：这里设置格式：2016：8：10
    [format setDateFormat:@"yyyy年MM月dd日"];
    //[format setDateFormat:@"yy-MM-dd"];
    //如果是这种：那么返回的时间是：2016-08-10
    
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    
    NSString *str = [format stringFromDate:date];
    return str;
}

+ (NSString *)formatHourMinutesSecond:(NSTimeInterval)time
{
    if (time < 0) return @"";
    
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    
    [format setDateFormat:@"HH时mm分ss秒"];
    
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:time/1000];
    
    NSString *str = [format stringFromDate:date];
    return str;
}

+ (NSString *)formatYearMonthDayHourMinutesSecond:(NSTimeInterval)time
{
    if (time < 0) return @"";
    
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    
    [format setDateFormat:@"yyyy年MM月dd日 HH时mm分ss秒"];
    
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:time/1000];
    
    NSString *str = [format stringFromDate:date];
    return str;
}

@end
