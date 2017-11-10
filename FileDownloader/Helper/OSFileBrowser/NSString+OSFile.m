//
//  NSString+OSFileDownloadsExtend.m
//  OSFileDownloader
//
//  Created by Ossey on 2017/6/12.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "NSString+OSFile.h"

#ifdef __clang__
#pragma clang diagnostic ignored "-Wformat-nonliteral"
#endif

#if TARGET_OS_SIMULATOR
    #if !TARGET_OS_TV
        static NSString * const rootPath = @"/Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk";
        #else
        static NSString * const rootPath = @"/Applications/Xcode-beta.app/Contents/Developer/Platforms/AppleTVSimulator.platform/Developer/SDKs/AppleTVSimulator.sdk";
    #endif

    #else
        static NSString * const rootPath = @"/";
#endif

@implementation NSString (OSFile)

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

- (unsigned long long)fileSize {
    unsigned long long totalSize = 0;
    NSFileManager *mgr = [NSFileManager defaultManager];
    // 是否为文件夹
    BOOL isDirectory = NO;
    
    // 路径是否存在
    BOOL exists = [mgr fileExistsAtPath:self isDirectory:&isDirectory];
    if (!exists) {
        return totalSize;
    }
    
    if (isDirectory) {
        // 获得文件夹的大小  == 获得文件夹中所有文件的总大小
        NSDirectoryEnumerator *enumerator = [mgr enumeratorAtPath:self];
        for (NSString *subpath in enumerator) {
            NSString *fullSubpath = [self stringByAppendingPathComponent:subpath];
            // 累加文件大小
            totalSize += [mgr attributesOfItemAtPath:fullSubpath error:nil].fileSize;
        }
    } else {
        totalSize = [mgr attributesOfItemAtPath:self error:nil].fileSize;
    }
    return totalSize;
}

+ (NSString *)stringForSize:(uint64_t)bytes {
    double     size;
    NSString * unit;
    
    if( bytes > ( 1024 * 1024 * 1024 ) )
    {
        unit  = NSLocalizedString( @"SizeGigaBytes", @"SizeGigaBytes" );
        size  = ( double )( ( double )( ( double )bytes / ( double )1024 ) / ( double )1024 ) / ( double )1024;
    }
    else if( bytes > ( 1024 * 1024 ) )
    {
        unit = NSLocalizedString( @"SizeMegaBytes", @"SizeMegaBytes" );
        size = ( double )( ( double )bytes / ( double )1024 ) / ( double )1024;
    }
    else if( bytes > 1024 )
    {
        unit = NSLocalizedString( @"SizeKiloBytes", @"SizeKiloBytes" );
        size = ( double )( ( double )bytes / ( double )1024 );
    }
    else
    {
        unit = NSLocalizedString( @"SizeBytes", @"SizeBytes" );
        size = bytes;
    }
    
    return [ NSString stringWithFormat: unit, size ];
}

- (BOOL)updateFileModificationDateForFilePath {
    NSDictionary *setDic =[NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate];
    return  [[NSFileManager defaultManager] setAttributes:setDic ofItemAtPath:self error:nil];
}

+ (NSString *)returnFormatString:(NSString *)str {
    return [str stringByReplacingOccurrencesOfString:@" " withString:@""];
}

/// Apple 官方提供的浮点型换算为百分比的方法，但是CFNumberFormatterRef不必多次malloc，会造成内存飙升
+ (NSString *)percentageString:(float)percent {
    static CFLocaleRef currentLocale = NULL;
    static CFNumberFormatterRef numberFormatter = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        currentLocale = CFLocaleCopyCurrent();
        numberFormatter = CFNumberFormatterCreate(NULL, currentLocale, kCFNumberFormatterPercentStyle);
    });
    CFNumberRef number = CFNumberCreate(NULL, kCFNumberFloatType, &percent);
    CFStringRef numberString = CFNumberFormatterCreateStringWithNumber(NULL, numberFormatter, number);
    CFRelease(number);
    CFRelease(numberString);
    return (__bridge NSString *)numberString;
}

+ (NSString *)getDownloadLocalFolderPath {
    NSString *cacheFolder = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSString *localFolderPath = [cacheFolder stringByAppendingPathComponent:@"OSFileDownloaderCacheFolder"];
    BOOL isDirectory, isExist;
    isExist = [[NSFileManager defaultManager] fileExistsAtPath:localFolderPath isDirectory:&isDirectory];
    if (!isExist || !isDirectory) {
        [[NSFileManager defaultManager] createDirectoryAtPath:localFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return localFolderPath;
}

+ (NSString *)getDownloadDisplayFolderPath {
    NSString *cacheFolder = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSString *localFolderPath = [cacheFolder stringByAppendingPathComponent:@"OSFileDownloaderDisplayFolder"];
    BOOL isDirectory, isExist;
    isExist = [[NSFileManager defaultManager] fileExistsAtPath:localFolderPath isDirectory:&isDirectory];
    if (!isExist || !isDirectory) {
        [[NSFileManager defaultManager] createDirectoryAtPath:localFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return localFolderPath;
}


+ (NSString *)getRootPath {
    return rootPath;
}

+ (NSString *)getDocumentPath {
    
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
}

+ (NSString *)getLibraryPath {
    NSArray *userPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    return [userPaths objectAtIndex:0];
}

+ (NSString *)getCachesPath {
    NSArray *userPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [userPaths objectAtIndex:0];
}

@end
