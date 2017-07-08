//
//  ExceptionUtils.h
//  ExceptionUtils
//
//  Created by xiaoyuan on 17/3/25.
//  Copyright © 2017年 erlinyou.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>


@interface ExceptionUtils : NSObject
extern NSString * getExceptionFilePath();
+ (void)configExceptionHandlerWithEmail:(NSString *)emailStr;
+ (void)configExceptionHandler;

@end


@interface FodlerViewController : UITableViewController <QLPreviewControllerDataSource>

- (instancetype)initWithPath:(NSString *)path;

@property (strong) NSString *path;
@property (strong) NSArray<NSString *> *files;
@property (nonatomic, assign) BOOL displayHiddenFiles;

@end
