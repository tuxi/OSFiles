//
//  BrowserWebView.h
//  WebBrowser
//
//  Created by Null on 2016/10/4.
//  Copyright © 2016年 Null. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BrowserWebView, WebModel, WebViewBackForwardList;

typedef void (^WebCompletionBlock)(NSString *, NSError *);

@protocol WebViewDelegate <NSObject>

@optional

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(BrowserWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;

@end

@interface BrowserWebView : UIWebView<UIWebViewDelegate>

@property (nonatomic, unsafe_unretained) WebModel *webModel;
@property (nonatomic, assign, readonly) BOOL isMainFrameLoaded;
@property (nonatomic, unsafe_unretained, readonly) UIActivityIndicatorView *indicatorView;
@property (nonatomic, unsafe_unretained, readonly) UILongPressGestureRecognizer *longPressGestureRecognizer;

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(WebCompletionBlock)completionHandler;

- (NSString *)mainFURL;
- (NSString *)mainFTitle;
- (WebViewBackForwardList *)webViewBackForwardList;

@end
