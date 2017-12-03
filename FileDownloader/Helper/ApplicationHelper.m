
//
//  ApplicationHelper.m
//  FileDownloader
//
//  Created by Swae on 2017/10/31.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "ApplicationHelper.h"
#import "NetworkTypeUtils.h"
#import "OSFileDownloaderManager.h"
#import "AppGroupManager.h"
#import "MainTabBarController.h"
#import "ZWUtility.h"
#import "MainNavigationController.h"


@interface ApplicationHelper () <ICSDrawerControllerDelegate, UITabBarControllerDelegate>

@end

@implementation ApplicationHelper

@dynamic helper;

+ (ApplicationHelper *)helper {
    static id _helper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _helper = self.new;
    });
    return _helper;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addNotification];
        [self commonInit];
        [AppGroupManager defaultManager];
    }
    return self;
}

- (void)commonInit {
    
    _pasteboard = [UIPasteboard generalPasteboard];
}

- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkChange:) name:NetworkTypeChangeNotification object:nil];
}

- (void)networkChange:(NSNotification *)notification {
    
    NetworkType type = [NetworkTypeUtils networkType];
    switch (type) {
        case NetworkTypeWIFI: {
            [[OSFileDownloaderManager sharedInstance] autoDownloadFailure];
            break;
        }
        case NetworkTypeWWAN: {
            [[OSFileDownloaderManager sharedInstance] failureAllDownloadTask];
            break;
        }
        default:
            break;
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - drawerViewController
////////////////////////////////////////////////////////////////////////


- (void)configureDrawerViewController {
    UIViewController *bvc = [UIViewController new];
    MainNavigationController *nav = [[MainNavigationController alloc] initWithRootViewController:bvc];
    MainTabBarController *tabBarController = [MainTabBarController new];
    tabBarController.delegate = self;
    self.drawerViewController  = [[ICSDrawerController alloc] initWithLeftViewController:nav
                                                                     centerViewController:tabBarController];
    self.drawerViewController.delegate = self;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - ICSDrawerControllerDelegate
////////////////////////////////////////////////////////////////////////

- (CGFloat)drawerDepthOfDrawerController:(ICSDrawerController *)drawerController {
    return [UIScreen mainScreen].bounds.size.width * 0.8;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UITabBarControllerDelegate
////////////////////////////////////////////////////////////////////////
- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    
    if ([viewController.title isEqualToString:@"个人中心"]) {
        
    }
    
    return  YES;
}


////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

/// 屏蔽ios文件不备份到icloud
- (void)addNotBackUpiCloud {
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *docPath = [documentPaths objectAtIndex:0];
    [self addSkipBackupAttributeToItemAtURL:docPath];
}

- (BOOL)addSkipBackupAttributeToItemAtURL:(NSString *)filePathString {
    NSURL *url = [NSURL fileURLWithPath:filePathString];
    assert([[NSFileManager defaultManager] fileExistsAtPath:[url path]]);
    
    NSError *error = nil;
    BOOL success = [url setResourceValue:[NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success){
        NSLog(@"Error excluding %@ from backup %@", [url lastPathComponent], error);
    }
    return success;
}

@end
