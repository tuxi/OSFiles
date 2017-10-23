//
//  BaseNavigationViewController.m
//  WebBrowser
//
//  Created by Null on 2017/7/13.
//  Copyright © 2017年 Null. All rights reserved.
//

#import "BaseNavigationViewController.h"

@implementation BaseNavigationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationBarHidden = YES;
    
    self.restorationIdentifier = @"baseNavigationController";
}

@end
