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
#import "DownloadsViewController.h"
#import "SmileAuthenticator.h"
#import "BaseNavigationViewController.h"
#import "OSFileCollectionViewController.h"
#import "OSFileDownloaderConfiguration.h"
#import "AppGroupManager.h"
#import "OSFile.h"

@interface MainTabBarController () <SmileAuthenticatorDelegate>

@end

@implementation MainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    OSFileCollectionViewController *fileBrowserVc = [[OSFileCollectionViewController alloc] initWithDirectoryArray:@[
                                                                     [NSString getICloudCacheFolder],
                                                                     [NSString getDownloadDisplayFolderPath],
                                                                     [NSString getDocumentPath],
                                                                     [AppGroupManager getAPPGroupSharePath]
                                                                     ]];
    
    NSArray *marupFiles = [OSFile markupFilePathsWithNeedReload:YES];
    OSFileCollectionViewController *starBrowserVc = [[OSFileCollectionViewController alloc] initWithDirectoryArray:marupFiles
                                                                                                                     ];
    starBrowserVc.displayMarkupFiles = YES;
    [self addChildVC:fileBrowserVc imageNamed:@"TabFiles" title:@"我的文件"];
    [self addChildVC:[DownloadsViewController new] imageNamed:@"TabDownloads" title:@"缓存"];
    [self addChildVC:starBrowserVc imageNamed:@"TabStar" title:@"标记"];
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
    nav.tabBarItem.image = [[UIImage imageNamed:name] xy_changeImageColorWithColor:[UIColor whiteColor]];
    UIImage *selectedImage = [UIImage imageNamed:[name stringByAppendingString:@"Filled"]];
    nav.tabBarItem.selectedImage = [selectedImage xy_changeImageColorWithColor:ColorRedGreenBlue(110, 206, 250)];
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

#pragma mark - ICSDrawerControllerPresenting

- (void)drawerControllerWillOpen:(ICSDrawerController *)drawerController {
    self.view.userInteractionEnabled = NO;
}

- (void)drawerControllerDidOpen:(ICSDrawerController *)drawerController {
    self.view.userInteractionEnabled = YES;
}

- (void)drawerControllerWillClose:(ICSDrawerController *)drawerController {
    self.view.userInteractionEnabled = NO;
}

- (void)drawerControllerDidClose:(ICSDrawerController *)drawerController {
    self.view.userInteractionEnabled = YES;
}


@end
