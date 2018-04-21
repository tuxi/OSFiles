//
//  AppGroupManager.m
//  FileDownloader
//
//  Created by Swae on 2017/11/11.
//  Copyright © 2017年 alpface. All rights reserved.
//

#import "AppGroupManager.h"
#import "OSFileCollectionViewController.h"
#import "UIViewController+XYExtensions.h"
#import "MacroMethod.h"
#import "MacroConstants.h"

NSString * const APP_URL_SCHEMES = @"OSFiledownloader://";
NSString * const APP_GROUP_IDENTIFIER = @"group.com.alpface.files";
NSString * const AppGroupFuncNameKey = @"funcName";
NSString * const AppGroupFolderPathKey = @"filePath";
NSString * const AppGroupRemoteURLPathKey = @"URL";

@interface AppGroupManager ()

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSURL *url;

@end

@implementation AppGroupManager

+ (instancetype)defaultManager {
    static id _manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [self.alloc initWithGroupIdentifier:APP_GROUP_IDENTIFIER];
    });
    return _manager;
}


- (instancetype)initWithGroupIdentifier:(NSString *)group {
    if (self = [super init]) {
        self.identifier = group;
        self.url = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:group];
        [self creatFilePathWithPath:[self.class getAPPGroupDocumentPath]];
        [self creatFilePathWithPath:[self.class getAPPGroupSharePath]];
    }
    return self;
}

- (BOOL)moveItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:srcPath]) {
        NSLog(@"Error: fromPath Not Exist");
        return NO;
    }
    NSString *headerComponent = [dstPath stringByDeletingLastPathComponent];
    if ([self creatFilePathWithPath:headerComponent]) {
        if ([fileManager fileExistsAtPath:dstPath]) {
            [fileManager removeItemAtPath:dstPath error:nil];
        }
        NSError *err = nil;
        BOOL yet = [fileManager moveItemAtPath:srcPath toPath:dstPath error:&err];
        return yet;
    } else {
        return NO;
    }
}

- (BOOL)copyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:srcPath]) {
        NSLog(@"Error: fromPath Not Exist");
        return NO;
    }
    NSString *headerComponent = [dstPath stringByDeletingLastPathComponent];
    if ([self creatFilePathWithPath:headerComponent]) {
        if ([fileManager fileExistsAtPath:dstPath]) {
            [fileManager removeItemAtPath:dstPath error:nil];
        }
        NSError *err = nil;
        BOOL yet = [fileManager copyItemAtPath:srcPath toPath:dstPath error:&err];
        return yet;
    } else {
        return NO;
    }
}

- (BOOL)createFileAtPath:(NSString *)path contents:(NSData *)data {
    BOOL ret = YES;
    ret = [self creatFileWithPath:path];
    if (ret) {
        ret = [data writeToFile:path atomically:YES];
        if (!ret) {
            NSLog(@"%s Failed",__FUNCTION__);
        }
    } else {
        NSLog(@"%s Failed",__FUNCTION__);
    }
    return ret;
}

- (BOOL)isFileExist:(NSString *)filePath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return ([fileManager fileExistsAtPath:filePath]);
}

- (BOOL)creatFilePathWithPath:(NSString *)filePath {
    BOOL isSuccess = YES;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL temp = [fileManager fileExistsAtPath:filePath];
    if (temp) {
        return YES;
    }
    NSError *error;
    isSuccess = [fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:&error];
    return isSuccess;
}

//创建文件
- (BOOL)creatFileWithPath:(NSString *)filePath {
    BOOL isSuccess = YES;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL temp = [fileManager fileExistsAtPath:filePath];
    if (temp) {
        return YES;
    }
    NSError *error;
    //stringByDeletingLastPathComponent:删除最后一个路径节点
    NSString *dirPath = [filePath stringByDeletingLastPathComponent];
    isSuccess = [fileManager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&error];
    if (error) {
        NSLog(@"creat File Failed. errorInfo:%@",error);
    }
    if (!isSuccess) {
        return isSuccess;
    }
    isSuccess = [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    return isSuccess;
}

+ (NSString *)getAPPGroupDocumentPath {
    NSString *string = [[self getAPPGroupHomePath] stringByAppendingPathComponent:@"Documents"];
    
    return string;
}

+ (NSString *)getAPPGroupHomePath {
    NSURL *groupURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:APP_GROUP_IDENTIFIER];
    NSString *string = [groupURL path];
    return string;
}

+ (NSString *)getAPPGroupSharePath {
    NSString *string = [[self getAPPGroupHomePath] stringByAppendingPathComponent:@"Share"];
    return string;
}

+ (BOOL)isAppGroupPath:(NSString *)path {
    NSString *groupURL = [self getAPPGroupHomePath];
    return [path hasPrefix:groupURL];
}

- (void)openAPP:(NSString *)appUrl info:(NSDictionary *)info {
    [self clearJumapPath];
    NSURL *URL = [NSURL URLWithString:appUrl];
    if ([[UIApplication sharedApplication] canOpenURL:URL]) {
        if (info) {
            [self saveJumpAPP:appUrl andInfo:info];
        }
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:NULL];
        } else {
            [[UIApplication sharedApplication] openURL:URL];
        }
    }
    
}

- (void)openAPP {
    [self openAPP:APP_URL_SCHEMES info:nil];
}

- (void)openUrlCallBack {
    NSDictionary *info = [self readInfoFromDocument];
    NSString *funcName = info[AppGroupFuncNameKey];
    if (!funcName.length) {
        return;
    }
    if ([funcName isEqualToString:@"share"]) {
        //        NSString *folderPath = info[AppGroupFolderPathKey];
        UITabBarController *tabBarVc = [UIViewController xy_tabBarController];
        tabBarVc.selectedIndex = 2;
        UINavigationController *nac = [UIViewController xy_currentNavigationController];
        NSArray *array = nac.viewControllers;
        OSFileCollectionViewController *vc = array.firstObject;
        if (!vc) {
            return;
        }
        [nac setViewControllers:@[vc] animated:YES];
        
        /// 只进入分享页面
        UIViewController *subFolderVc = [vc previewControllerWithFilePath:[self.class getAPPGroupSharePath]];
        [vc showDetailController:subFolderVc parentPath:[self.class getAPPGroupSharePath]];
    }
    else if ([funcName isEqualToString:@"openURL"]) {
        NSURL *url = info[AppGroupRemoteURLPathKey];
        if ([url isKindOfClass:[NSString class]]) {
            url = [NSURL URLWithString:(NSString *)url];
        }
        // 打开网页
        NSNotification *notify = [NSNotification notificationWithName:kOpenInNewWindowNotification object:self userInfo:@{@"url": url}];
        [Notifier postNotification:notify];
        [UIViewController xy_tabBarController].selectedIndex = 0;
    }
}

- (NSDictionary *)readInfoFromDocument {
    NSString *jumpPath = [self appJumpPath];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if ([self isFileExist:jumpPath]) {
        NSArray *arr = [fileManager contentsOfDirectoryAtPath:jumpPath error:nil];
        if (!arr.count) {
            return nil;
        }
        NSString *url = arr.firstObject;
        if ([APP_URL_SCHEMES hasPrefix:url]) {
            NSString *infoPath = [jumpPath stringByAppendingPathComponent:url];
            return [NSDictionary dictionaryWithContentsOfFile:infoPath];
        }
        else {
            return nil;
        }
    }
    else {
        return nil;
    }
}

- (NSString *)appJumpPath {
    NSString *groupDocument = [AppGroupManager getAPPGroupDocumentPath];
    NSString *jumpPath = [groupDocument stringByAppendingPathComponent:@"appJumpDic"];
    if (![self isFileExist:jumpPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:jumpPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return jumpPath;
}

- (void)saveJumpAPP:(NSString *)appUrl andInfo:(NSDictionary *)info {
    NSString *jumpPath = [self appJumpPath];
    NSString *infoUrl = [jumpPath stringByAppendingPathComponent: [appUrl substringToIndex:appUrl.length -3]];
    [info writeToFile:infoUrl atomically:YES];
}

- (void)clearJumapPath {
    NSString *jumpPath = [self appJumpPath];
    [[NSFileManager defaultManager] removeItemAtPath:jumpPath error:nil];
}

@end
