//
//  OSFilePreviewViewController.h
//  FileBrowser
//
//  Created by xiaoyuan on 05/08/2014.
//  Copyright © 2014 xiaoyuan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>
#import <WebKit/WebKit.h>

@class OSFileAttributeItem;

@interface OSPreviewViewController : QLPreviewController

@end

@interface OSFilePreviewViewController : UIViewController {
    UITextView *_textView;
    WKWebView *_webView;
    OSFileAttributeItem *_fileItem;
}

@property (nonatomic, copy, readonly) OSFileAttributeItem *fileItem;

- (instancetype)initWithFileItem:(OSFileAttributeItem *)fileItem;
+ (BOOL)canOpenFile:(NSString *)filePath;

@end

