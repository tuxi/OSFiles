//
//  ExceptionUtils.m
//  ExceptionUtils
//
//  Created by xiaoyuan on 17/3/25.
//  Copyright © 2017年 erlinyou.com. All rights reserved.
//

#import "ExceptionUtils.h"
#import <objc/runtime.h>
#import "XYSuspensionMenu.h"
#import "NSString+OSFile.h"
#import "OSFileCollectionViewController.h"

#define APPVERSION_STRING [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#define kRandomColor [UIColor colorWithRed:arc4random_uniform(256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:0.95]

static NSString * _emailStr;

@implementation ExceptionUtils

+ (void)configExceptionHandler {
    
    [self configExceptionHandlerWithEmail:nil];
    
#if DEBUG
    [self configSystemDebugWindow];
#endif
}

+ (void)configSystemDebugWindow {
    
    Class debugClass = NSClassFromString(@"UIDebuggingInformationOverlay");
    [debugClass performSelector:NSSelectorFromString(@"prepareDebuggingOverlay")];
}

+ (void)configExceptionHandlerWithEmail:(NSString *)emailStr {
    _emailStr = emailStr;
    NSSetUncaughtExceptionHandler(&saveExceptionLog);
    
#if DEBUG
    createExceptionLogBtn();
#endif
}

static void createExceptionLogBtn() {
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2. * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        suspensionMenuWindow();
    });
}

static void suspensionMenuWindow()
{
    @autoreleasepool {
        SuspensionMenuWindow *menuView = [[SuspensionMenuWindow alloc] initWithFrame:CGRectMake(0, 0, 300, 300) itemSize:CGSizeMake(50, 50)];
        [menuView.centerButton setImage:[UIImage imageNamed:@"aws-icon"] forState:UIControlStateNormal];
        menuView.shouldOpenWhenViewWillAppear = NO;
        menuView.shouldHiddenCenterButtonWhenOpen = YES;
        menuView.shouldCloseWhenDeviceOrientationDidChange = YES;
        UIImage *image = [UIImage imageNamed:@"mm.jpg"];
        menuView.backgroundImageView.image = image;
        HypotenuseAction *item = nil;
        {
            item = [HypotenuseAction actionWithType:UIButtonTypeSystem handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
                pushToTestLog(menuView);
            }];
            [menuView addAction:item];
            [item.hypotenuseButton setTitle:@"查看日志" forState:UIControlStateNormal];
            [item.hypotenuseButton setBackgroundColor:[UIColor colorWithRed:arc4random_uniform(256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:1.0]];
            item.hypotenuseButton.layer.cornerRadius = 12.0;
        }
        {
            item = [HypotenuseAction actionWithType:UIButtonTypeSystem handler:^(HypotenuseAction * _Nonnull action, SuspensionMenuView * _Nonnull menuView) {
                
                OSFileCollectionViewController *vc = [[OSFileCollectionViewController alloc]
                                                      initWithFilePathArray:@[                                                                                                            [NSString getRootPath],[NSString getDocumentPath]]
                                                      
                                                      controllerMode:OSFileCollectionViewControllerModeDefault];
                
                [menuView showViewController:vc animated:YES];
            }];
            [menuView addAction:item];
            [item.hypotenuseButton setTitle:@"沙盒" forState:UIControlStateNormal];
            [item.hypotenuseButton setBackgroundColor:[UIColor colorWithRed:arc4random_uniform(256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:1.0]];
            item.hypotenuseButton.layer.cornerRadius = 12.0;
        }
        
        
        [menuView showWithCompetion:NULL];

    }
    
}




static __unused void pushToTestLog(SuspensionMenuWindow *menuView) {
    NSError *error = nil;
    NSString *log = [NSString stringWithContentsOfFile:getExceptionFilePath() encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        log = error.localizedDescription;
    }
    
    UIViewController *vc = [[NSClassFromString(@"ExceptionViewController") alloc] performSelector:@selector(initWithLog:) withObject:log];
    [menuView showViewController:vc animated:YES];
    
}

static __unused void openTestWindow(SuspensionMenuWindow *menuView, BOOL isSelected) {
#if DEBUG
    Class someClass = NSClassFromString(@"UIDebuggingInformationOverlay");
    id obj = [someClass performSelector:NSSelectorFromString(@"overlay")];
    [obj performSelector:NSSelectorFromString(@"toggleVisibility")];
#endif
    [menuView close];
    
}


static void saveExceptionLog(NSException *exception) {
    NSString *exLog = [NSString stringWithFormat:@"发生异常的时间: %@;\n软件版本: %@ \n系统版本: %@\n异常名称: %@;\n异常原因: %@;\n详细信息: %@;\n函数栈描述: \n%@;\n**********************华丽的分割线**********************\n", dateToString([NSDate date]), APPVERSION_STRING, [[UIDevice currentDevice]systemVersion],exception.name, exception.reason, exception.userInfo ,[exception.callStackSymbols componentsJoinedByString:@"\n"]];
    
    writeToFile(exLog, getExceptionFilePath());
    if (isValidateEmail(_emailStr)) {
        sendExLogByEmailWithLog(exLog);
    }
    NSLog(@"%@", getExceptionFilePath());
}

static BOOL isValidateEmail(NSString *email) {
    
    if (!email || [email  isEqualToString:@""]) return NO;
    NSString *emailRegex = @"^[a-zA-Z0-9_-]+@[a-zA-Z0-9_-]+(\\.[a-zA-Z0-9_-]+)+$";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:email];
}

static void sendExLogByEmailWithLog(NSString *log) {
    NSString *title = @"Bug 反馈!";
    NSString *body = [NSString stringWithFormat:@"Thank You!<br><br><br>" "%@", log];
    NSString *urlStr = [NSString stringWithFormat:@"mailto://%@?subject=%@&body=%@",_emailStr ,title, body];
    NSURL *url = [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [[UIApplication sharedApplication] openURL:url];
}

static NSString * dateToString(NSDate *date) {
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterFullStyle];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    return dateString;
}

static void writeToFile(NSString *text, NSString *filePath) {
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
    [fileHandle seekToEndOfFile];
    NSData* stringData  = [text dataUsingEncoding:NSUTF8StringEncoding];
    [fileHandle writeData:stringData];
    [fileHandle closeFile];
}

NSString * getExceptionFilePath() {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"exceptionLog.txt"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
    }
    return path;
}

@end

@interface ExceptionViewController : UIViewController <UITextViewDelegate>
@property (nonatomic, copy) NSString *logText;
@property (nonatomic, weak) UITextView *textView;
@end

@implementation ExceptionViewController
{
    BOOL _shouldShowSuspension;
}
- (instancetype)initWithLog:(NSString *)logText {
    if (self = [super init]) {
        _logText = logText;
        _shouldShowSuspension = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"ExceptionLog";
    self.textView.text = self.logText;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CGFloat const SUSPENSIONVIEW_WH = 60;
    CGRect frame = CGRectMake(CGRectGetWidth([UIScreen mainScreen].bounds) - SUSPENSIONVIEW_WH, CGRectGetHeight([UIScreen mainScreen].bounds)-64-SUSPENSIONVIEW_WH, SUSPENSIONVIEW_WH, SUSPENSIONVIEW_WH);
    if (_textView.contentSize.height > [UIScreen mainScreen].bounds.size.height*1.5) {
        _shouldShowSuspension = YES;
        SuspensionView *sv = [self.view showSuspensionViewWithFrame:frame];
        [sv setBackgroundColor:[UIColor blueColor]];
        sv.layer.cornerRadius = 8.8;
        [sv.layer setMasksToBounds:YES];
        [sv setTitle:@"Bottom" forState:UIControlStateNormal];
        [sv.titleLabel setFont:[UIFont systemFontOfSize:12 weight:1.0]];
        sv.leanEdgeInsets = UIEdgeInsetsMake(20, 0, 64, 0);
        __weak typeof(self) weakSelf = self;
        __weak typeof(sv) weakSv = sv;
        sv.clickCallBack = ^{
            if (!weakSv.selected) {
                [weakSelf.textView scrollRangeToVisible:NSMakeRange(weakSelf.logText.length, 1)];
                [weakSv setTitle:@"Top" forState:UIControlStateNormal];
            } else {
                [weakSelf.textView scrollRangeToVisible:NSMakeRange(0, 1)];
                [weakSv setTitle:@"Bottom" forState:UIControlStateNormal];
            }
            weakSv.selected = !weakSv.selected;
        };
    }
    
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if (_textView) {
        [_textView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
    }
    
}
- (UITextView *)textView {
    if (_textView == nil) {
        UITextView *tv = [UITextView new];
        [self.view addSubview:tv];
        _textView = tv;
        _textView.editable = NO;
        _textView.delegate = self;
    }
    return _textView;
}

@end

