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

+ (NSString *)getDownloadDisplayImageFolderPath {
    NSString *cacheFolder = [self getDownloadDisplayFolderPath];
    NSString *localFolderPath = [cacheFolder stringByAppendingPathComponent:@"图片"];
    BOOL isDirectory, isExist;
    isExist = [[NSFileManager defaultManager] fileExistsAtPath:localFolderPath isDirectory:&isDirectory];
    if (!isExist || !isDirectory) {
        [[NSFileManager defaultManager] createDirectoryAtPath:localFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return localFolderPath;
}

+ (NSString *)getDownloadDisplayVideoFolderPath {
    NSString *cacheFolder = [self getDownloadDisplayFolderPath];
    NSString *localFolderPath = [cacheFolder stringByAppendingPathComponent:@"视频"];
    BOOL isDirectory, isExist;
    isExist = [[NSFileManager defaultManager] fileExistsAtPath:localFolderPath isDirectory:&isDirectory];
    if (!isExist || !isDirectory) {
        [[NSFileManager defaultManager] createDirectoryAtPath:localFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return localFolderPath;
}

+ (NSString *)getDownloadDisplayOtherFolderPath {
    NSString *cacheFolder = [self getDownloadDisplayFolderPath];
    NSString *localFolderPath = [cacheFolder stringByAppendingPathComponent:@"其他"];
    BOOL isDirectory, isExist;
    isExist = [[NSFileManager defaultManager] fileExistsAtPath:localFolderPath isDirectory:&isDirectory];
    if (!isExist || !isDirectory) {
        [[NSFileManager defaultManager] createDirectoryAtPath:localFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return localFolderPath;
}

+ (NSString *)getICloudCacheFolder {
    NSString *cacheFolder = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSString *localFolderPath = [cacheFolder stringByAppendingPathComponent:@"OSFilesICloudDrive"];
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

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

- (OSFileType)os_fileType {
    
    if
        (
         ([[self.pathExtension lowercaseString] isEqualToString: @"mp3"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"aac"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"aifc"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"aiff"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"caf"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"m4a"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"m4r"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"3gp"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"wav"])
         )
    {
        return OSFileTypeAudio;
    }
    
    if
        (
         ([[self.pathExtension lowercaseString] isEqualToString: @"m4v"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"mov"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"avi"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"mpg"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"mp4"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"mov"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"wmv"])
         )
    {
        return OSFileTypeVideo;
    }
    
    if
        (
         ([[self.pathExtension lowercaseString] isEqualToString: @"png"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"tif"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"tiff"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"jpg"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"jpeg"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"gif"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"bmp"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"bmpf"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"ico"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"cur"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"xbm"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"webp"])
         )
    {
        return OSFileTypeImage;
    }
    if
        (
         ([[self.pathExtension lowercaseString] isEqualToString: @"zip"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"rar"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"7zf"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"tar"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"tgz"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"tbz"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"dmg"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"app"]
          || [[self.pathExtension lowercaseString] isEqualToString: @"ipa"])
         )
    {
        return OSFileTypeArchive;
    }
    
    if
        (
         ([[self.pathExtension lowercaseString] isEqualToString: @"exe"])
         )
    {
        return OSFileTypeWindows;
    }
    return OSFileTypeOther;
}

+ (BOOL)isPDF:(NSString *)filePath {
    BOOL state = NO;
    
    if (filePath != nil) // Must have a file path
    {
        const char *path = [filePath fileSystemRepresentation];
        
        int fd = open(path, O_RDONLY); // Open the file
        
        if (fd > 0) // We have a valid file descriptor
        {
            const char sig[1024]; // File signature buffer
            
            ssize_t len = read(fd, (void *)&sig, sizeof(sig));
            
            state = (strnstr(sig, "%PDF", len) != NULL);
            
            close(fd); // Close the file
        }
    }
    
    return state;
}

@end
