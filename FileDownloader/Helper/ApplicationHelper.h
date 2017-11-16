//
//  ApplicationHelper.h
//  FileDownloader
//
//  Created by Swae on 2017/10/31.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSDrawerController.h"

@interface ApplicationHelper : NSObject

@property (nonatomic, strong, class) ApplicationHelper *helper;
@property (nonatomic, strong, readonly) UIPasteboard *pasteboard;

@property (nonatomic, strong) OSDrawerController *drawerViewController;

- (void)configureDrawerViewController;

@end
