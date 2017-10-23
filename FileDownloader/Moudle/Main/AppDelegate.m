//
//  AppDelegate.m
//  OSFileDownloader
//
//  Created by Ossey on 2017/6/10.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "AppDelegate.h"
#import "MainTabBarController.h"
#import "OSFileDownloader.h"
#import "OSFileDownloaderManager.h"
#import "NetworkTypeUtils.h"
#import "ExceptionUtils.h"
#import "OSAuthenticatorHelper.h"
#import "OSLoaclNotificationHelper.h"


#import "KeyboardHelper.h"
#import "MenuHelper.h"
#import "BrowserViewController.h"
#import "WebServer.h"
#import "ErrorPageHelper.h"
#import "SessionRestoreHelper.h"
#import "TabManager.h"
#import "PreferenceHelper.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

static NSString * const UserAgent = @"Mozilla/5.0 (iPhone; CPU iPhone OS 10_0 like Mac OS X) AppleWebKit/602.1.38 (KHTML, like Gecko) Version/10.0 Mobile/14A300 Safari/602.1";

@interface AppDelegate ()  {
    UIBackgroundTaskIdentifier _bgTask;
}

@property (nonatomic, assign) NSInteger pasteboardChangeCount;

@end

@implementation AppDelegate

- (void)dealloc{
    [Notifier removeObserver:self name:UIPasteboardChangedNotification object:nil];
}

- (void)setAudioPlayInBackgroundMode{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    NSError *setCategoryError = nil;
    BOOL success = [audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&setCategoryError];
    if (!success) { /* handle the error condition */ }
    
    NSError *activationError = nil;
    success = [audioSession setActive:YES error:&activationError];
    if (!success) { /* handle the error condition */ }
}

- (void)handlePasteboardNotification:(NSNotification *)notify{
    self.pasteboardChangeCount = [UIPasteboard generalPasteboard].changeCount;
}

- (void)presentPasteboardChangedAlertWithURL:(NSURL *)url{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"新窗口打开剪切板网址" message:@"您是否需要在新窗口中打开剪切板中的网址？" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
        NSNotification *notify = [NSNotification notificationWithName:kOpenInNewWindowNotification object:self userInfo:@{@"url": url}];
        [Notifier postNotification:notify];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (void)applicationStartPrepare{
    [self setAudioPlayInBackgroundMode];
    [[KeyboardHelper sharedInstance] startObserving];
    [[MenuHelper sharedInstance] setItems];
    
    [Notifier addObserver:self selector:@selector(handlePasteboardNotification:) name:UIPasteboardChangedNotification object:nil];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    DDLogDebug(@"Home Path : %@", HomePath);
    
    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024
                                                         diskCapacity:32 * 1024 * 1024
                                                             diskPath:nil];
    [NSURLCache setSharedURLCache:URLCache];
    
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [MainTabBarController new];
    [self.window makeKeyAndVisible];
    [ExceptionUtils configExceptionHandler];
    
    /// 注册本地通知
    [[OSLoaclNotificationHelper sharedInstance] registerLocalNotificationWithBlock:^(UILocalNotification *localNotification) {
        /// 注册完成后回调
        NSLog(@"%@", localNotification);
        
        // ios8后，需要添加这个注册，才能得到授权
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            UIUserNotificationType type =  UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
            UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:type
                                                                                     categories:nil];
            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
            // 通知重复提示的单位，可以是天、周、月
            localNotification.repeatInterval = 0;
        } else {
            // 通知重复提示的单位，可以是天、周、月
            localNotification.repeatInterval = 0;
        }
        
    }];
    
    UILocalNotification *localNotification = [launchOptions valueForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (localNotification) {
        // 当程序启动时，就有本地通知需要推送，就手动调用一次didReceiveLocalNotification
        [self application:application didReceiveLocalNotification:localNotification];
    }
    
    [[OSAuthenticatorHelper sharedInstance] initAuthenticator];
    
    
    /////
    [ErrorPageHelper registerWithServer:[WebServer sharedInstance]];
    [SessionRestoreHelper registerWithServer:[WebServer sharedInstance]];
    
    [[WebServer sharedInstance] start];
    
    //解决UIWebView首次加载页面时间过长问题,设置UserAgent减少跳转和判断
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent" : UserAgent}];
    
    [TabManager sharedInstance];    //load archive data ahead
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self applicationStartPrepare];
    });
    
    
    return YES;
}

/// 此方法是本地通知会触发的方法，当点击通知横幅进入app时会调用
- (void)application:(UIApplication *)application didReceiveLocalNotification:(nonnull UILocalNotification *)notification {
    
    // 取消所有通知
    [application cancelAllLocalNotifications];
    [[[UIAlertView alloc] initWithTitle:@"下载通知" message:[OSLoaclNotificationHelper sharedInstance].notifyMessage delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
    
    // 点击通知后，就让图标上的数字减1
    application.applicationIconBadgeNumber -= 1;
}

/// 当有电话进来或者锁屏，此时应用程会挂起，调用此方法，此方法一般做挂起前的工作，比如关闭网络，保存数据
- (void)applicationWillResignActive:(UIApplication *)application {
    // 图标上的数字减1
    application.applicationIconBadgeNumber -= 1;
    [[OSAuthenticatorHelper sharedInstance] applicationWillResignActiveWithShowCoverImageView];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[OSAuthenticatorHelper sharedInstance] applicationDidBecomeActiveWithRemoveCoverImageView];
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    
    if (self.pasteboardChangeCount != pasteboard.changeCount) {
        self.pasteboardChangeCount = pasteboard.changeCount;
        NSURL *url = pasteboard.URL;
        if (url && ![[PreferenceHelper URLForKey:KeyPasteboardURL] isEqual:url]) {
            [PreferenceHelper setURL:url forKey:KeyPasteboardURL];
            [self presentPasteboardChangedAlertWithURL:url];
        }
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    _bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        
        // 10分钟后执行这里，应该进行一些清理工作，如断开和服务器的连接等
        // stopped or ending the task outright.
        [application endBackgroundTask:_bgTask];
        _bgTask = UIBackgroundTaskInvalid;
    }];
    if (_bgTask == UIBackgroundTaskInvalid) {
        NSLog(@"failed to start background task!");
    }
    // Start the long-running task and return immediately.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Do the work associated with the task, preferably in chunks.
        NSTimeInterval timeRemain = 0;
        do {
            [NSThread sleepForTimeInterval:5];
            if (_bgTask != UIBackgroundTaskInvalid) {
                timeRemain = [application backgroundTimeRemaining];
                NSLog(@"Time remaining: %f",timeRemain);
            }
        } while(_bgTask!= UIBackgroundTaskInvalid && timeRemain > 0);
        // 如果改为timeRemain > 5*60,表示后台运行5分钟
        // done!
        // 如果没到10分钟，也可以主动关闭后台任务，但这需要在主线程中执行，否则会出错
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_bgTask != UIBackgroundTaskInvalid) {
                // 和上面10分钟后执行的代码一样
                // if you don't call endBackgroundTask, the OS will exit your app.
                [application endBackgroundTask:_bgTask];
                _bgTask = UIBackgroundTaskInvalid;
            }
        });
    });
}
- (void)applicationWillEnterForeground:(UIApplication *)application {
    // 如果没到10分钟又打开了app,结束后台任务
    if (_bgTask != UIBackgroundTaskInvalid) {
        [application endBackgroundTask:_bgTask];
        _bgTask = UIBackgroundTaskInvalid;
    }
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler {
    
    [[OSFileDownloaderManager sharedInstance].downloader setBackgroundSessionCompletionHandler:completionHandler];
}

// Enable UIWebView video landscape
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window{
    static NSString *kAVFullScreenViewControllerStr = @"AVFullScreenViewController";
    UIViewController *presentedViewController = [window.rootViewController presentedViewController];
    
    if (presentedViewController && [presentedViewController isKindOfClass:NSClassFromString(kAVFullScreenViewControllerStr)] && [presentedViewController isBeingDismissed] == NO) {
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Preseving and Restoring State

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder{
    return YES;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder{
    return YES;
}



@end
