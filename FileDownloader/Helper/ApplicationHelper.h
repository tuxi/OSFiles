//
//  ApplicationHelper.h
//  FileDownloader
//
//  Created by Swae on 2017/10/31.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICSDrawerController.h"

@interface ApplicationHelper : NSObject

@property (nonatomic, strong, class) ApplicationHelper *helper;
@property (nonatomic, strong, readonly) UIPasteboard *pasteboard;

@property (nonatomic, strong) ICSDrawerController *drawerViewController;

- (void)configureDrawerViewController;

/// 屏蔽ios文件不备份到icloud
- (void)addNotBackUpiCloud;

@end
