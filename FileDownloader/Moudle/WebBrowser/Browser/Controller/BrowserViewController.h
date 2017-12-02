//
//  BrowserViewController.h
//  WebBrowser
//
//  Created by Null on 16/7/30.
//  Copyright © 2016年 Null. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"
#import "BrowserBottomToolBar.h"

@interface BrowserViewController : BaseViewController<UIScrollViewDelegate>

+ (instancetype)sharedInstance;

- (void)findInPageDidUpdateCurrentResult:(NSInteger)currentResult;
- (void)findInPageDidUpdateTotalResults:(NSInteger)totalResults;
- (void)findInPageDidSelectForSelection:(NSString *)selection;

@end
