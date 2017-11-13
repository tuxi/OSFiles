//
//  AppGroupManager.h
//  FileDownloader
//
//  Created by Swae on 2017/11/11.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const APP_URL_SCHEMES;
extern NSString * const APP_GROUP_IDENTIFIER;
extern NSString * const AppGroupFuncNameKey;
extern NSString * const AppGroupFolderPathKey;

@interface AppGroupManager : NSObject

+ (instancetype)defaultManager;
- (BOOL)moveItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath;
- (BOOL)copyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath;
- (BOOL)createFileAtPath:(NSString *)path contents:(NSData *)data;
+ (NSString *)getAPPGroupDocumentPath;
+ (NSString *)getAPPGroupSharePath;
+ (NSString *)getAPPGroupHomePath;
+ (BOOL)isAppGroupPath:(NSString *)path;
- (void)openAPP:(NSString *)appUrl info:(NSDictionary *)info;
- (void)openAPP;
- (void)openUrlCallBack;

@end
