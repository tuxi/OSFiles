//
//  OSFilePreviewViewController.m
//  FileBrowser
//
//  Created by xiaoyuan on 05/08/2014.
//  Copyright © 2014 xiaoyuan. All rights reserved.
//

#import "OSFilePreviewViewController.h"
#import "NSString+OSFile.h"
#import "OSFileAttributeItem.h"
#import "UIViewController+OSStatusBarStyle.h"

@interface OSFilePreviewViewController ()

@end


#pragma mark *** OSFilePreviewViewController ***



@implementation OSFilePreviewViewController

@synthesize fileItem = _fileItem;

////////////////////////////////////////////////////////////////////////
#pragma mark - initialize
////////////////////////////////////////////////////////////////////////

- (instancetype)initWithFileItem:(OSFileAttributeItem *)fileItem {
    self = [super init];
    if (self) {
        _fileItem = fileItem;
        _textView = [[UITextView alloc] initWithFrame:self.view.bounds];
        _textView.editable = NO;
        _textView.backgroundColor = [UIColor whiteColor];
        
        _webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
        
        [self loadFileWithItem:fileItem];
        
    }
    return self;
}

#ifdef __IPHONE_9_0
- (NSArray<id<UIPreviewActionItem>> *)previewActionItems {
    
    if (!self.fileItem || self.fileItem.isDirectory) {
        return nil;
    }
    
    UIPreviewAction *action1 = [UIPreviewAction actionWithTitle:@"info" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        [self infoAction];
    }];
    
    UIPreviewAction *action2 = [UIPreviewAction actionWithTitle:@"share" style:UIPreviewActionStyleDestructive handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        [self shareAction];
    }];
    
    NSArray *actions = @[action1, action2];
    
    // 将所有的actions 添加到group中
    UIPreviewActionGroup *group1 = [UIPreviewActionGroup actionGroupWithTitle:@"more operation" style:UIPreviewActionStyleDefault actions:actions];
    NSArray *group = @[group1];
    
    return group;
}
#endif

- (void)infoAction {
    
    [[[UIAlertView alloc] initWithTitle:@"File info" message:[self.fileItem description] delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil] show];
}

- (void)shareAction {
    NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:self.fileItem.displayName];
    NSError *error = nil;
    [[NSFileManager defaultManager] copyItemAtPath:self.fileItem.path toPath:tmpPath error:&error];
    
    if (error) {
        NSLog(@"ERROR: %@", error);
    }
    UIActivityViewController *shareActivity = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:tmpPath]] applicationActivities:nil];
    
    shareActivity.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
    };
    [self.navigationController presentViewController:shareActivity animated:YES completion:nil];
}


////////////////////////////////////////////////////////////////////////
#pragma mark - Other
////////////////////////////////////////////////////////////////////////

+ (NSArray *)fileExtensions {
    return @[@"plist",
             @"strings",
             @"xcconfig",
             @"version",
             @"archive",
             @"gps",
             @"txt",
             @"md",
             @"podspec",
             @"h",
             @"m",
             @"c",
             @"cpp",
             @"lock",
             @"pbxproj",
             @"xcworkspacedata",
             @"xcuserstate",
             @"json",
             @"xml",
             @"pch",
             @"storyboard",
             @"xib",
             @"moc",
             @"p",
             @"java",
             @"py",
             @"asc",
             //// 下面为精彩旅图公司支持的扩展
             @"bas",
             @"pan",
             @"cdt",
             @"pkin",
             @"xm",
             @"peng",
             @"ini",
             @"flag",
             @"log",
             @"spd",
             @"alt",
             @"gd",
             @"foot",
             @"param",
             @"hdrf",
             @"ddt",
             @"shp",
             @"pub",
             @"date",
             @"cam",
             @"tfd",
             @"hd",
             @"db"];
}

+ (BOOL)canOpenFile:(NSString *)filePath {
    if (!filePath.length || ![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return NO;
    }
    if ([[self fileExtensions] containsObject:filePath.pathExtension.lowercaseString]) {
        return YES;
    }
    return NO;
}


- (void)loadFileWithItem:(OSFileAttributeItem *)item {
    
    if ([item.fileExtension.lowercaseString isEqualToString:@"db"]) {
        // 可以读取数据库后展示
        [_textView setText:@"db"];
        self.view = _textView;
    }
    
    else {
        if ([item.fileExtension.lowercaseString isEqualToString:@"plist"] ||
            [item.fileExtension.lowercaseString isEqualToString:@"archive"]) {
            NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:item.path];
            [_textView setText:[d description]];
            self.view = _textView;
            _webView = nil;
        }
        else {
            if (@available(iOS 9.0, *)) {
                NSData *data = [NSData dataWithContentsOfFile:item.path];
                [_webView loadData:data MIMEType:self.fileItem.mimeType characterEncodingName:@"UTF-8" baseURL:[NSURL fileURLWithPath:item.parentDirectoryPath]];
                self.view = _webView;
                _textView = nil;
            } else {
                NSString *d = [NSString stringWithContentsOfFile:item.path encoding:NSUTF8StringEncoding error:nil];
                [_textView setText:d];
                self.view = _textView;
                _webView = nil;
            }
        }
        
    }
    
    self.title = item.displayName;
}

@end

@implementation OSPreviewViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setOs_statusBarStyle:UIStatusBarStyleLightContent];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

