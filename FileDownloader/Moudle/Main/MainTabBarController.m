//
//  MainTabBarController.m
//  MVVMDemo
//
//  Created by mofeini on 17/2/12.
//  Copyright © 2017年 com.test.demo. All rights reserved.
//

#import "MainTabBarController.h"
#import "MainNavigationController.h"
#import "OSSettingViewController.h"
//#import "FilesViewController.h"
#import "DownloadsViewController.h"
#import "SmileAuthenticator.h"
#import "BrowserViewController.h"
#import "BaseNavigationViewController.h"
#import "OSFileCollectionViewController.h"
#import "OSFileDownloaderConfiguration.h"

@interface MainTabBarController () <SmileAuthenticatorDelegate>

@end

@implementation MainTabBarController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addChildVC:[BrowserViewController sharedInstance] imageNamed:@"TabBrowser" title:@"浏览器" navClass:[BaseNavigationViewController class]];
    [self addChildVC:[DownloadsViewController new] imageNamed:@"TabDownloads" title:@"下载"];
    
    [self addChildVC:[[OSFileCollectionViewController alloc] initWithDirectoryArray:@[
                                                                                      [NSString getDownloadLocalFolderPath],
                                                                                      [NSString getDocumentPath]
                                                                                      ]] imageNamed:@"TabFiles" title:@"文件管理"];
    [self addChildVC:[OSSettingViewController new] imageNamed:@"TabMore" title:@"更多"];
    
    [SmileAuthenticator sharedInstance].delegate = self;
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([SmileAuthenticator hasPassword]) {
        [SmileAuthenticator sharedInstance].securityType = INPUT_TOUCHID;
        [[SmileAuthenticator sharedInstance] presentAuthViewControllerAnimated:NO];
    }
}

- (void)addChildVC:(UIViewController *)vc imageNamed:(NSString *)name title:(NSString *)title {
    [self addChildVC:vc imageNamed:name title:title navClass:NULL];
}

- (void)addChildVC:(UIViewController *)vc imageNamed:(NSString *)name title:(NSString *)title navClass:(Class)navClass {
    if (!navClass) {
        navClass = [MainNavigationController class];
    }
    MainNavigationController *nav = [[navClass alloc] initWithRootViewController:vc];
    nav.tabBarItem.image = [UIImage imageNamed:name].xy_originalMode;
    nav.tabBarItem.selectedImage = [UIImage imageNamed:[name stringByAppendingString:@"Filled"]];
    nav.tabBarItem.title = title;
    [self addChildViewController:nav];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

////////////////////////////////////////////////////////////////////////
#pragma mark - AuthenticatorDelegate
////////////////////////////////////////////////////////////////////////

- (void)userFailAuthenticationWithCount:(NSInteger)failCount{
    NSLog(@"userFailAuthenticationWithCount: %ld", (long)failCount);
}

- (void)userSuccessAuthentication{
    NSLog(@"userSuccessAuthentication");
}

- (void)userTurnPasswordOn{
    NSLog(@"userTurnPasswordOn");
}

- (void)userTurnPasswordOff{
    NSLog(@"userTurnPasswordOff");
}

- (void)userChangePassword{
    NSLog(@"userChangePassword");
}

- (void)AuthViewControllerPresented{
    NSLog(@"presentAuthViewController");
}

- (void)AuthViewControllerDismissed:(UIViewController*)previousPresentedVC{
    NSLog(@"dismissAuthViewController, previousPresentedVC: %@", previousPresentedVC);
    if (previousPresentedVC) {
        [self presentViewController:previousPresentedVC animated:YES completion:nil];
    }
}

@end
