//
//  SessionRestoreHelper.h
//  WebBrowser
//
//  Created by Null on 2017/3/16.
//  Copyright © 2017年 Null. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WebServer;

@interface SessionRestoreHelper : NSObject

+ (void)registerWithServer:(WebServer *)server;

@end
