//
//  ShareViewController.m
//  FileManagerShareExtension
//
//  Created by Swae on 2017/11/11.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "ShareViewController.h"

@interface ShareViewController ()

@end

@implementation ShareViewController

// 如果是return No, 那么发送按钮就无法点击, 如果return YES, 那么发送按钮就可以点击
- (BOOL)isContentValid {
    // Do validation of contentText and/or NSExtensionContext attachments here
    return YES;
}

// 发送按钮的Action事件
- (void)didSelectPost {
    // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
    // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}

// 这个方法是用来返回items的一个方法, 而且返回值是数组
- (NSArray *)configurationItems {
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    return @[];
}

@end
