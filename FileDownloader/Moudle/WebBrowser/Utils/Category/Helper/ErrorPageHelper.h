//
//  ErrorPageHelper.h
//  WebBrowser
//
//  Created by Null on 2017/2/18.
//  Copyright © 2017年 Null. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WebServer,BrowserWebView;

@interface ErrorPageHelper : NSObject

+ (void)registerWithServer:(WebServer *)server;
+ (void)showPageWithError:(NSError *)error URL:(NSURL *)url inWebView:(BrowserWebView *)webView;

@end
