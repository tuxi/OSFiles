//
//  NSString+OSFileDownloadsExtend.h
//  OSFileDownloader
//
//  Created by Ossey on 2017/6/12.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (OSFile)

+ (NSString *)transformedFileSizeValue:(NSNumber *)value;
+ (NSString *)stringWithRemainingTime:(NSInteger)secs;
- (unsigned long long)fileSize;

+ (NSString *)stringForSize:(uint64_t)bytes;
/// 修改文件时间
- (BOOL)updateFileModificationDateForFilePath;
+ (NSString *)returnFormatString:(NSString *)str;

/// Apple 官方提供的浮点型换算为百分比的方法，但是CFNumberFormatterRef不必多次malloc，会造成内存飙升
+ (NSString *)percentageString:(float)percent;
@end

