//
//  FileDownloadConst.h
//  Boobuz
//
//  Created by xiaoyuan on 18/10/2017.
//  Copyright © 2017 erlinyou.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#define dispatch_main_async_safe(block)\
if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}

#ifdef DEBUG
#define DLog(fmt, ...) NSLog((@"<%s : %d> %s  " fmt), [[[NSString stringWithUTF8String:__FILE__] lastPathComponent]   UTF8String], __LINE__, __PRETTY_FUNCTION__,  ##__VA_ARGS__);
#else
#define DLog(...)
#endif

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#define OSPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)


FOUNDATION_EXTERN NSNotificationName const FileDownloadProgressChangeNotification;
FOUNDATION_EXTERN NSNotificationName const FileDownloadSussessNotification;
FOUNDATION_EXTERN NSNotificationName const FileDownloadFailureNotification;
FOUNDATION_EXTERN NSNotificationName const FileDownloadCanceldNotification;
FOUNDATION_EXTERN NSNotificationName const FileDownloadStartedNotification;
FOUNDATION_EXTERN NSNotificationName const FileDownloadPausedNotification;
FOUNDATION_EXTERN NSNotificationName const FileDownloadWaittingNotification;
FOUNDATION_EXTERN NSNotificationName const FileDownloadTotalProgressCanceldNotification;
