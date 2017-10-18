//
//  OSDownloadConst.h
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



FOUNDATION_EXTERN NSString * const OSFileDownloadProgressChangeNotification;
FOUNDATION_EXTERN NSString * const OSFileDownloadSussessNotification;
FOUNDATION_EXTERN NSString * const OSFileDownloadFailureNotification;
FOUNDATION_EXTERN NSString * const OSFileDownloadCanceldNotification;
FOUNDATION_EXTERN NSString * const OSFileDownloadStartedNotification;
FOUNDATION_EXTERN NSString * const OSFileDownloadPausedNotification;
FOUNDATION_EXTERN NSString * const OSFileDownloadTotalProgressCanceldNotification;
