//
//  MainTabBarController.m
//  MVVMDemo
//
//  Created by mofeini on 17/2/12.
//  Copyright © 2017年 com.test.demo. All rights reserved.
//

#import "MainTabBarController.h"
#import "MainNavigationController.h"
#import "MoreViewController.h"
#import "BrowserViewController.h"
#import "FilesViewController.h"
#import "DownloadsViewController.h"

@interface MainTabBarController ()

@end

@implementation MainTabBarController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addChildVC:[BrowserViewController new] imageNamed:@"TabBrowser" title:@"Browser"];
    [self addChildVC:[DownloadsViewController new] imageNamed:@"TabDownloads" title:@"Downloads"];
    [self addChildVC:[FilesViewController new] imageNamed:@"TabFiles" title:@"Files"];
    [self addChildVC:[MoreViewController new] imageNamed:@"TabMore" title:@"More"];
    
    
}


- (void)addChildVC:(UIViewController *)vc imageNamed:(NSString *)name title:(NSString *)title {
    MainNavigationController *nav = [[MainNavigationController alloc] initWithRootViewController:vc];
    nav.tabBarItem.image = [UIImage imageNamed:name].xy_originalMode;
    nav.tabBarItem.selectedImage = [UIImage imageNamed:[name stringByAppendingString:@"Filled"]];
    nav.tabBarItem.title = title;
    [self addChildViewController:nav];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}


@end
