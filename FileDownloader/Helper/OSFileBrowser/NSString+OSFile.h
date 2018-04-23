//
//  NSString+OSFileDownloadsExtend.h
//  OSFileDownloader
//
//  Created by alpface on 2017/6/12.
//  Copyright © 2017年 alpface. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    OSFileTypeOther,
    OSFileTypeImage,
    OSFileTypeVideo,
    OSFileTypeAudio,
    OSFileTypeArchive,
    OSFileTypeWindows,
}
OSFileType;

@class OSFile;

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

/// 文件下载过程中存储的文件夹
+ (NSString *)getDownloadLocalFolderPath;
/// 文件下载完成后移动到最终的文件夹
+ (NSString *)getDownloadDisplayFolderPath;
/// 下载文件夹中的图片目录
+ (NSString *)getDownloadDisplayImageFolderPath;
/// 下载文件夹中的视频目录
+ (NSString *)getDownloadDisplayVideoFolderPath;
/// 下载文件夹中的其他类型文件目录
+ (NSString *)getDownloadDisplayOtherFolderPath;
/// 下载文件夹中的压缩类型文件目录
+ (NSString *)getDownloadDisplayArchiveFolderPath;
+ (NSString *)getRootPath;
+ (NSString *)getDocumentPath;
+ (NSString *)getLibraryPath;
+ (NSString *)getCachesPath;
/// iCloud文件临时保存的目录
+ (NSString *)getICloudCacheFolder;

- (OSFileType)os_fileType;

+ (NSString *)getMarkupCachePath;
+ (NSString *)getOSFileBrowserCachePath;

@end

