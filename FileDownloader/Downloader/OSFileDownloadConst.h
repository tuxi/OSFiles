//
//  OSFileDownloadConst.h
//  Boobuz
//
//  Created by xiaoyuan on 18/10/2017.
//  Copyright © 2017 erlinyou.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#define XYDispatch_main_async_safe(block)\
    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL),  dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {\
        block();\
    } else {\
        dispatch_async(dispatch_get_main_queue(), block);\
    }

#ifdef DEBUG
#  define DLog(fmt, ...) NSLog((@"<%s : %d> %s  " fmt), \
    [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, __PRETTY_FUNCTION__,  ##__VA_ARGS__);
#  else
    #define DLog(...)
#endif

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#   define OSPerformSelectorLeakWarning(Stuff) \
    do { \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
    Stuff; \
    _Pragma("clang diagnostic pop") \
    } while (0)

typedef NS_ENUM(NSUInteger, OSFileDownloadStatus) {
    OSFileDownloadStatusNotStarted = 0,
    /// 暂停下载
    OSFileDownloadStatusPaused,
    /// 下载中
    OSFileDownloadStatusDownloading,
    /// 下载完成
    OSFileDownloadStatusSuccess,
    /// 等待下载
    OSFileDownloadStatusWaiting,
    /// 下载失败
    OSFileDownloadStatusFailure,
};

FOUNDATION_EXTERN NSNotificationName const OSFileDownloadProgressChangeNotification;
FOUNDATION_EXTERN NSNotificationName const OSFileDownloadSussessNotification;
FOUNDATION_EXTERN NSNotificationName const OSFileDownloadFailureNotification;
FOUNDATION_EXTERN NSNotificationName const OSFileDownloadCanceldNotification;
FOUNDATION_EXTERN NSNotificationName const OSFileDownloadStartedNotification;
FOUNDATION_EXTERN NSNotificationName const OSFileDownloadPausedNotification;
FOUNDATION_EXTERN NSNotificationName const OSFileDownloadWaittingNotification;
FOUNDATION_EXTERN NSNotificationName const OSFileDownloadTotalProgressCanceldNotification;
