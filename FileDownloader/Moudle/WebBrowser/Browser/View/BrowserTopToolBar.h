//
//  BrowserTopToolBar.h
//  WebBrowser
//
//  Created by Null on 2016/10/12.
//  Copyright © 2016年 Null. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BrowserWebView.h"
#import "NJKWebViewProgress.h"

@interface BrowserTopToolBar : UIView <WebViewDelegate, NJKWebViewProgressDelegate>

- (void)setTopURLOrTitle:(NSString *)urlOrTitle;

@end
