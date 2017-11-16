//
//  BrowserBottomToolBar.h
//  WebBrowser
//
//  Created by Null on 2016/11/6.
//  Copyright © 2016年 Null. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BrowserWebView.h"
#import "BrowserBottomToolBarHeader.h"

@interface BrowserBottomToolBar : UIToolbar

@property (nonatomic, weak) id<BrowserBottomToolBarButtonClickedDelegate> browserButtonDelegate;
@property (nonatomic, copy) void (^switchPageButtonActionBlock)(UIButton *btn);
@property (nonatomic, strong) UIButton *switchPageButton;

@end
