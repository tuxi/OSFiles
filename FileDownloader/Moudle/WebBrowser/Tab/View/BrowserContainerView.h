//
//  BrwoserContentView.h
//  WebBrowser
//
//  Created by Null on 2016/10/9.
//  Copyright © 2016年 Null. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BrowserWebView.h"
#import "BrowserBottomToolBarHeader.h"

typedef void(^TabCompletion)(WebModel *webModel, BrowserWebView *browserWebView);

@interface BrowserContainerView : UIView <BrowserBottomToolBarButtonClickedDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, readonly) UIScrollView *scrollView;
@property (nonatomic, readonly, weak) BrowserWebView *webView;

- (void)restoreWithCompletionHandler:(TabCompletion)completion animation:(BOOL)animation;

@end
