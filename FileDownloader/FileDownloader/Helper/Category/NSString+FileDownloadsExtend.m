//
//  NSString+FileDownloadsExtend.m
//  FileDownloader
//
//  Created by Ossey on 2017/6/12.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "NSString+FileDownloadsExtend.h"

@implementation NSString (FileDownloadsExtend)

+ (NSString *)transformedFileSizeValue:(NSNumber *)value {
    
    double convertedValue = [value doubleValue];
    int multiplyFactor = 0;
    
    NSArray *tokens = [NSArray arrayWithObjects:@"B",@"KB",@"MB",@"GB",@"TB",@"PB", @"EB", @"ZB", @"YB",nil];
    
    while (convertedValue > 1024) {
        convertedValue /= 1024;
        multiplyFactor++;
    }
    
    return [NSString stringWithFormat:@"%4.2f %@",convertedValue, [tokens objectAtIndex:multiplyFactor]];
}


+ (NSString *)contentTypeForImageData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
        case 0xFF:
            return @"image/jpeg";
        case 0x89:
            return @"image/png";
        case 0x47:
            return @"image/gif";
        case 0x49:
        case 0x4D:
            return @"image/tiff";
        case 0x52:
            // R as RIFF for WEBP
            if ([data length] < 12) {
                return nil;
            }
            
            NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
            if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
                return @"image/webp";
            }
            
            return nil;
    }
    return nil;
}

+ (NSString *)stringWithRemainingTime:(NSInteger)secs {
    NSInteger hour = secs / 3600;
    NSInteger min = (secs % 3600) / 60;
    NSInteger sec = (secs % 3600) % 60;
    NSString *hourStr = @"";
    NSString *minStr = @"";
    NSString *secStr = @"";
    if (hour <= 0) {
        hourStr = @"";
    }
    else{
        if (hour > 0 && hour <= 9) {
            hourStr = [NSString stringWithFormat:@"0%ld",(long)hour];
        }
        else{
            hourStr = [NSString stringWithFormat:@"%ld",(long)hour];
        }
    }
    if (min >= 0 && min <= 9) {
        minStr = [NSString stringWithFormat:@"0%ld",(long)min];
    }
    else{
        minStr = [NSString stringWithFormat:@"%ld",(long)min];
    }
    if (sec >= 0 && sec <= 9) {
        secStr = [NSString stringWithFormat:@"0%ld",(long)sec];
    }
    else{
        secStr = [NSString stringWithFormat:@"%ld",(long)sec];
    }
    if (hour > 0) {
        return [NSString stringWithFormat:@"%@:%@:%@",hourStr,minStr,secStr];
    }
    else{
        return [NSString stringWithFormat:@"00:%@:%@",minStr,secStr];
    }
}


@end
