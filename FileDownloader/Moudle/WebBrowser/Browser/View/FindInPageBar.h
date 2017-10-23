//
//  FindInPageBar.h
//  WebBrowser
//
//  Created by Null on 2017/5/17.
//  Copyright © 2017年 Null. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FindInPageBar : UIView

@property (nonatomic, assign) NSInteger currentResult;
@property (nonatomic, assign) NSInteger totalResults;
@property (nonatomic, copy) NSString *text;

@end
