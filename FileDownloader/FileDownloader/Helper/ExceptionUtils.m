//
//  ExceptionUtils.m
//  ExceptionUtils
//
//  Created by xiaoyuan on 17/3/25.
//  Copyright © 2017年 erlinyou.com. All rights reserved.
//

#import "ExceptionUtils.h"
#import <objc/runtime.h>
#import "SuspensionControl.h"
#import "NSString+FileDownloadsExtend.h"

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
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        suspensionMenuWindow();
    });
}

static void suspensionMenuWindow()
{
    @autoreleasepool {
        int idx = 0;
        NSMutableArray *items = [NSMutableArray arrayWithCapacity:0];
        while (idx < 4) {
            MenuBarHypotenuseItem *item = [[MenuBarHypotenuseItem alloc] initWithButtonType:OSButtonType1];
            [items addObject:item];
            [item.hypotenuseButton setBackgroundColor:kRandomColor];
            item.hypotenuseButton.layer.cornerRadius = 12.8;
            [item.hypotenuseButton.layer setMasksToBounds:YES];
            switch (idx) {
                case 0:
                {
                    [item.hypotenuseButton setTitle:@"Exception\nLog" forState:UIControlStateNormal];
                }
                    break;
                case 1:
                {
                    [item.hypotenuseButton setTitle:@"Back" forState:UIControlStateNormal];
                }
                    break;
                case 2:
                    [item.hypotenuseButton setTitle:@"SandBox" forState:UIControlStateNormal];
                    NSInteger i = 0;
                    while (i < 2) {
                        MenuBarHypotenuseItem *itemI = [[MenuBarHypotenuseItem alloc] initWithButtonType:OSButtonType1];
                        [item.moreHypotenusItems addObject:itemI];
                        [itemI.hypotenuseButton setBackgroundColor:kRandomColor];
                        itemI.hypotenuseButton.layer.cornerRadius = 12.8;
                        [itemI.hypotenuseButton.layer setMasksToBounds:YES];
                        
                        switch (i) {
                            case 0:
                                [itemI.hypotenuseButton setTitle:@"Caches" forState:UIControlStateNormal];
                                break;
                            case 1:
                                [itemI.hypotenuseButton setTitle:@"Home" forState:UIControlStateNormal];
                                break;
                            default:
                                break;
                        }
                        i++;
                    }
                    
                    break;
                case 3:
                {
                    [item.hypotenuseButton setTitle:@"more" forState:UIControlStateNormal];
                    NSInteger i = 0;
                    while (i < 3) {
                        MenuBarHypotenuseItem *itemI = [[MenuBarHypotenuseItem alloc] initWithButtonType:OSButtonType1];
                        [item.moreHypotenusItems addObject:itemI];
                        [itemI.hypotenuseButton setBackgroundColor:kRandomColor];
                        itemI.hypotenuseButton.layer.cornerRadius = 12.8;
                        [itemI.hypotenuseButton.layer setMasksToBounds:YES];
                        
                        switch (i) {
                            case 0:
                                [itemI.hypotenuseButton setTitle:@"0" forState:UIControlStateNormal];
                                break;
                            case 1:
                                [itemI.hypotenuseButton setTitle:@"Debug\nWindow" forState:UIControlStateNormal];
                                break;
                            case 2:
                                [itemI.hypotenuseButton setTitle:@"2" forState:UIControlStateNormal];
                                break;
                            default:
                                break;
                        }
                        i++;
                    }
                    
                }
                    break;
                default:
                    break;
            }
            idx++;
        }
        
        SuspensionMenuWindow *menuView = [[SuspensionMenuWindow alloc] initWithFrame:CGRectMake(0, 0, 280, 280)];
        __weak typeof(menuView) weakMenuView = menuView;
        menuView.moreButtonClickBlock = ^(NSInteger index, MenuBarHypotenuseItem *item) {
            if ([item.hypotenuseButton.titleLabel.text isEqualToString:@"more"]) {
                switch (index) {
                    case 0:
                        [weakMenuView dismiss];
                        break;
                    case 1:
                        openTestWindow(weakMenuView, weakMenuView.menuBarItems[index].hypotenuseButton.selected);
                        break;
                    case 2:
                        
                        [weakMenuView dismiss];
                        break;
                        
                    default:
                        break;
                }
            }
            
            if ([item.hypotenuseButton.titleLabel.text isEqualToString:@"沙盒浏览"]) {
                NSString *path = nil;
                switch (index) {
                    case 0:
                    {
                        path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
                    }
                        break;
                    case 1:
                    {
                        path = NSHomeDirectory();
                    }
                        break;
                    default:
                        break;
                }
                
                FodlerViewController *vc = [[FodlerViewController alloc] initWithPath:path];
                vc.displayHiddenFiles = YES;
                [weakMenuView testPushViewController:vc animated:YES];
                
                
            }
            
            
        };
        menuView.isOnce = YES;
        menuView.shouldShowWhenViewWillAppear = NO;
        menuView.shouldHiddenCenterButtonWhenShow = YES;
        menuView.shouldDismissWhenDeviceOrientationDidChange = YES;
        [menuView setMenuBarItems:items itemSize:CGSizeMake(55, 55)];
        [menuView.centerButton setImage:[UIImage imageNamed:@"aws-icon"] forState:UIControlStateNormal];
        
        
        menuView.menuBarClickBlock = ^(NSInteger index, MenuBarHypotenuseItem *item) {
            switch (index) {
                case 0:
                {
                }
                    break;
                case 1:
                {
                    [weakMenuView dismiss];
                }
                    break;
                case 2:
                {
                    [weakMenuView dismiss];
                }
                    
                    break;
                case 3:
                {
                    
                }
                    break;
                    
                default:
                    break;
            }
            
            
        };
        
        menuView.showCompletion = ^{
            weakMenuView.menuBarItems[1].hypotenuseButton.enabled = YES;
            [weakMenuView.menuBarItems[1].hypotenuseButton setBackgroundColor:kRandomColor];
            [weakMenuView.menuBarItems[1].hypotenuseButton setTitleColor:kRandomColor forState:UIControlStateNormal];
            
        };
    }
    
}




static __unused void pushToTestLog(SuspensionMenuWindow *menuView) {
    NSError *error = nil;
    NSString *log = [NSString stringWithContentsOfFile:getExceptionFilePath() encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        log = error.localizedDescription;
    }
    
    UIViewController *vc = [[NSClassFromString(@"ExceptionViewController") alloc] performSelector:@selector(initWithLog:) withObject:log];
    [menuView testPushViewController:vc animated:YES];
    
}

static void openTestWindow(SuspensionMenuWindow *menuView, BOOL isSelected) {
#if DEBUG
    Class someClass = NSClassFromString(@"UIDebuggingInformationOverlay");
    id obj = [someClass performSelector:NSSelectorFromString(@"overlay")];
    [obj performSelector:NSSelectorFromString(@"toggleVisibility")];
#endif
    [menuView dismiss];
    
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

#pragma mark *** FodlerViewController ***

@interface FileTableViewCell : UITableViewCell

@property (nonatomic, assign) NSString *path;

@end


@interface FilePreviewViewController : UIViewController {
    UITextView *_textView;
    UIImageView *_imageView;
}

@property (nonatomic, copy) NSString *filePath;

+ (BOOL)canHandleExtension:(NSString *)fileExt;
- (instancetype)initWithFile:(NSString *)file;

@end

#ifdef __IPHONE_9_0
@interface FodlerViewController () <UIViewControllerPreviewingDelegate>
#else
@interface FodlerViewController ()
#endif

@property (nonatomic, strong) UILongPressGestureRecognizer *longPress;
@property (nonatomic, copy) void (^longPressCallBack)(NSIndexPath *indexPath);
@property (nonatomic, strong) NSIndexPath *indexPath;

@end

@implementation FodlerViewController


////////////////////////////////////////////////////////////////////////
#pragma mark - Initialize
////////////////////////////////////////////////////////////////////////

- (instancetype)initWithPath:(NSString *)path {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        
        self.path = path;
        _displayHiddenFiles = NO;
        [self loadFile:path];
        
    }
    return self;
}

- (void)loadFile:(NSString *)path {
    NSError *error = nil;
    NSArray *tempFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    if (error) {
        NSLog(@"Error: %@", error);
    }
    self.files = [self sortedFiles:tempFiles];
    if (!_displayHiddenFiles) {
        self.files = [self removeHiddenFilesFromFiles:self.files];
    }
}

- (void)setDisplayHiddenFiles:(BOOL)displayHiddenFiles {
    if (_displayHiddenFiles == displayHiddenFiles) {
        return;
    }
    _displayHiddenFiles = displayHiddenFiles;
    [self loadFile:self.path];
    
}

- (NSArray *)removeHiddenFilesFromFiles:(NSArray *)files {
    NSIndexSet *indexSet = [files indexesOfObjectsPassingTest:^BOOL(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj hasPrefix:@"."];
    }];
    NSMutableArray *tempFiles = [self.files mutableCopy];
    [tempFiles removeObjectsAtIndexes:indexSet];
    return tempFiles;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [self.path lastPathComponent];
    UIBarButtonItem *rightBarButton1 = [[UIBarButtonItem alloc] initWithTitle:@"Reload" style:UIBarButtonItemStyleDone target:self action:@selector(reloadFiles)];
    self.navigationItem.rightBarButtonItems = @[rightBarButton1];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self check3DTouch];
}

- (void)reloadFiles {
    [self loadFile:self.path];
    [self.tableView reloadData];
}

- (void)check3DTouch {
    /// 检测是否有3d touch 功能
    if ([self respondsToSelector:@selector(traitCollection)]) {
        if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)]) {
            if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
                // 支持3D Touch
                if ([self respondsToSelector:@selector(registerForPreviewingWithDelegate:sourceView:)]) {
                    [self registerForPreviewingWithDelegate:self sourceView:self.view];
                    self.longPress.enabled = NO;
                }
            } else {
                // 不支持3D Touch
                self.longPress.enabled = YES;
            }
        }
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - 3D Touch Delegate
////////////////////////////////////////////////////////////////////////

#ifdef __IPHONE_9_0
- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    _indexPath = indexPath;
    UIViewController *vc = [self previewControllerByIndexPath:indexPath];
    // 预览区域大小(可不设置)
    vc.preferredContentSize = CGSizeMake(0, 320);
    return vc;
}



- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [self showViewController:viewControllerToCommit sender:self];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    
    [self check3DTouch];
}

#endif


////////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewDataSource
////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FileTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([FileTableViewCell class])];
    if (cell == nil) {
        cell = [[FileTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:NSStringFromClass([FileTableViewCell class])];
    }
    
    cell.path = [self.path stringByAppendingPathComponent:self.files[indexPath.row]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    
    self.indexPath = indexPath;
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"more operation" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"share" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self shareAction];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"info" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
        [self infoAction];
        
    }]];
    [self presentViewController:alert animated:YES completion:nil];
    
    
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.indexPath = indexPath;
    UIViewController *vc = [self previewControllerByIndexPath:indexPath];
    [self jumpToDetailControllerToViewController:vc atIndexPath:indexPath];
}

- (void)jumpToDetailControllerToViewController:(UIViewController *)viewController atIndexPath:(NSIndexPath *)indexPath {
    NSString *newPath = [self.path stringByAppendingPathComponent:self.files[indexPath.row]];
    BOOL isDirectory;
    BOOL fileExists = [[NSFileManager defaultManager ] fileExistsAtPath:newPath isDirectory:&isDirectory];
    if (fileExists) {
        if (isDirectory) {
            FodlerViewController *vc = (FodlerViewController *)viewController;
            [self.navigationController showViewController:vc sender:self];
        } else if ([FilePreviewViewController canHandleExtension:[newPath pathExtension]]) {
            FilePreviewViewController *preview = (FilePreviewViewController *)viewController;
            preview.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"back" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonClick)];
            UINavigationController *detailNavController = [[UINavigationController alloc] initWithRootViewController:preview];
            
            [self.navigationController showDetailViewController:detailNavController sender:self];
        } else {
            QLPreviewController *preview = (QLPreviewController *)viewController;
            preview.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"back" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonClick)];
            UINavigationController *detailNavController = [[UINavigationController alloc] initWithRootViewController:preview];
            
            [self.navigationController showDetailViewController:detailNavController sender:self];
        }
    }
}

- (UIViewController *)previewControllerByIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath) {
        return nil;
    }
    NSString *newPath = [self.path stringByAppendingPathComponent:self.files[indexPath.row]];
    BOOL isDirectory;
    BOOL fileExists = [[NSFileManager defaultManager ] fileExistsAtPath:newPath isDirectory:&isDirectory];
    UIViewController *vc = nil;
    if (fileExists) {
        if (isDirectory) {
            vc = [[FodlerViewController alloc] initWithPath:newPath];
            
        } else if ([FilePreviewViewController canHandleExtension:[newPath pathExtension]]) {
            vc = [[FilePreviewViewController alloc] initWithFile:newPath];
        } else {
            QLPreviewController *preview= [[QLPreviewController alloc] init];
            preview.dataSource = self;
            vc = preview;
        }
    }
    return vc;
}

- (void)backButtonClick {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewDelegate
////////////////////////////////////////////////////////////////////////

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *currentPath = [self.path stringByAppendingPathComponent:self.files[indexPath.row]];
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:currentPath error:&error];
    if (error) {
        [[[UIAlertView alloc] initWithTitle:@"Remove error" message:nil delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil] show];
    }
    [self reloadFiles];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"delete";
}

////////////////////////////////////////////////////////////////////////
#pragma mark - QLPreviewControllerDataSource
////////////////////////////////////////////////////////////////////////

- (BOOL)previewController:(QLPreviewController *)controller shouldOpenURL:(NSURL *)url forPreviewItem:(id <QLPreviewItem>)item {
    
    return YES;
}

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return 1;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger) index {
    NSLog(@"index: %ld", self.tableView.indexPathForSelectedRow.row);
    // self.tableView.indexPathForSelectedRow 获取当前选中的IndexPath,
    // 注意: 当设置了[tableView deselectRowAtIndexPath:indexPath animated:YES]后，indexPathForSelectedRow为初始值
    NSString *newPath = [self.path stringByAppendingPathComponent:self.files[self.indexPath.row]];
    
    return [NSURL fileURLWithPath:newPath];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Sorted files
////////////////////////////////////////////////////////////////////////
- (NSArray *)sortedFiles:(NSArray *)files {
    return [files sortedArrayWithOptions:NSSortConcurrent usingComparator:^NSComparisonResult(NSString* file1, NSString* file2) {
        NSString *newPath1 = [self.path stringByAppendingPathComponent:file1];
        NSString *newPath2 = [self.path stringByAppendingPathComponent:file2];
        
        BOOL isDirectory1, isDirectory2;
        [[NSFileManager defaultManager ] fileExistsAtPath:newPath1 isDirectory:&isDirectory1];
        [[NSFileManager defaultManager ] fileExistsAtPath:newPath2 isDirectory:&isDirectory2];
        
        if (isDirectory1 && !isDirectory2) {
            return NSOrderedDescending;
        }
        
        return  NSOrderedAscending;
    }];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
////////////////////////////////////////////////////////////////////////

- (UILongPressGestureRecognizer *)longPress {
    
    if (!_longPress) {
        _longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(showPeek:)];
        [self.view addGestureRecognizer:_longPress];
    }
    return _longPress;
}

- (void)showPeek:(UILongPressGestureRecognizer *)longPress {
    if (longPress.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [longPress locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
        
        if (self.longPressCallBack) {
            self.longPressCallBack(indexPath);
        }
        
        self.longPress.enabled = NO;
        UIViewController *vc = [self previewControllerByIndexPath:indexPath];
        [self jumpToDetailControllerToViewController:vc atIndexPath:indexPath];
    }
}


- (void)infoAction {
    if (!self.indexPath) {
        return;
    }
    NSString *newPath = [self.path stringByAppendingPathComponent:self.files[self.indexPath.row]];
    NSDictionary *fileAtt = [[NSFileManager defaultManager] attributesOfItemAtPath:newPath error:nil];
    
    NSMutableString *attstring = @"".mutableCopy;
    [fileAtt enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key isEqualToString:NSFileSize]) {
        }
        [attstring appendString:[NSString stringWithFormat:@"%@:%@\n", key, obj]];
    }];
    
    [[[UIAlertView alloc] initWithTitle:@"File info" message:attstring delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil] show];
    self.indexPath = nil;
}

- (void)shareAction {
    if (!self.indexPath) {
        return;
    }
    NSString *newPath = [self.path stringByAppendingPathComponent:self.files[self.indexPath.row]];
    NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:newPath.lastPathComponent];
    NSError *error = nil;
    [[NSFileManager defaultManager] copyItemAtPath:newPath toPath:tmpPath error:&error];
    
    if (error) {
        NSLog(@"ERROR: %@", error);
    }
    UIActivityViewController *shareActivity = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:tmpPath]] applicationActivities:nil];
    
    shareActivity.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
    };
    [self.navigationController presentViewController:shareActivity animated:YES completion:nil];
    self.indexPath = nil;
}


@end

#pragma mark *** FilePreviewViewController ***



@implementation FilePreviewViewController

////////////////////////////////////////////////////////////////////////
#pragma mark - initialize
////////////////////////////////////////////////////////////////////////

- (instancetype)initWithFile:(NSString *)file {
    self = [super init];
    if (self) {
        _filePath = file;
        _textView = [[UITextView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _textView.editable = NO;
        _textView.backgroundColor = [UIColor whiteColor];
        
        _imageView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        _imageView.backgroundColor = [UIColor whiteColor];
        
        [self loadFile:file];
        
    }
    return self;
}

#ifdef __IPHONE_9_0
- (NSArray<id<UIPreviewActionItem>> *)previewActionItems {
    
    BOOL isDirectory;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:self.filePath isDirectory:&isDirectory];
    if (!fileExists || isDirectory) {
        return nil;
    }
    
    UIPreviewAction *action1 = [UIPreviewAction actionWithTitle:@"info" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        [self infoAction];
    }];
    
    UIPreviewAction *action2 = [UIPreviewAction actionWithTitle:@"share" style:UIPreviewActionStyleDestructive handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        [self shareAction];
    }];
    
    NSArray *actions = @[action1, action2];
    
    // 将所有的actions 添加到group中
    UIPreviewActionGroup *group1 = [UIPreviewActionGroup actionGroupWithTitle:@"more operation" style:UIPreviewActionStyleDefault actions:actions];
    NSArray *group = @[group1];
    
    return group;
}
#endif

- (void)infoAction {

    NSDictionary *fileAtt = [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:nil];
    
    NSMutableString *attstring = @"".mutableCopy;
    [fileAtt enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key isEqualToString:NSFileSize]) {
        }
        [attstring appendString:[NSString stringWithFormat:@"%@:%@\n", key, obj]];
    }];
    
    [[[UIAlertView alloc] initWithTitle:@"File info" message:attstring delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil] show];
}

- (void)shareAction {
    NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:self.filePath.lastPathComponent];
    NSError *error = nil;
    [[NSFileManager defaultManager] copyItemAtPath:self.filePath toPath:tmpPath error:&error];
    
    if (error) {
        NSLog(@"ERROR: %@", error);
    }
    UIActivityViewController *shareActivity = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:tmpPath]] applicationActivities:nil];
    
    shareActivity.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
    };
    [self.navigationController presentViewController:shareActivity animated:YES completion:nil];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Other
////////////////////////////////////////////////////////////////////////

+ (BOOL)canHandleExtension:(NSString *)fileExtension {
    return ([fileExtension.lowercaseString isEqualToString:@"plist"] || [fileExtension.lowercaseString isEqualToString:@"strings"] || [fileExtension.lowercaseString isEqualToString:@"xcconfig"]);
}

- (void)loadFile:(NSString *)file {
    if ([file.pathExtension.lowercaseString isEqualToString:@"plist"] || [file.pathExtension.lowercaseString isEqualToString:@"strings"]) {
        NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:file];
        [_textView setText:[d description]];
        self.view = _textView;
    } else if ([file.pathExtension.lowercaseString isEqualToString:@"xcconfig"]) {
        NSString *d = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
        [_textView setText:d];
        self.view = _textView;
    } else {
        _imageView.image = [UIImage imageWithContentsOfFile:file];
        self.view = _imageView;
    }
    
    self.title = file.lastPathComponent;
}

@end

@implementation FileTableViewCell

- (void)setPath:(NSString *)path {
    _path = path;
    
    BOOL isDirectory;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    self.textLabel.text = [path lastPathComponent];
    
    self.detailTextLabel.text = [NSString stringWithFormat:@"%@", [NSString transformedFileSizeValue:@([path fileSize])]];
    if (isDirectory) {
        self.imageView.image = [UIImage imageNamed:@"Folder"];
    } else if ([path.pathExtension.lowercaseString isEqualToString:@"png"]
               || [path.pathExtension.lowercaseString isEqualToString:@"jpg"]) {
        self.imageView.image = [UIImage imageNamed:@"Picture"];
        //        self.imageView.image = [UIImage imageWithContentsOfFile:path];
    } else {
        self.imageView.image = nil;
    }
    if (fileExists && !isDirectory) {
        self.accessoryType = UITableViewCellAccessoryDetailButton;
    } else {
        self.accessoryType = UITableViewCellAccessoryNone;
    }
    
}

@end
