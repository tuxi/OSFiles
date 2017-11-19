//
//  OSFileCollectionViewController.m
//  FileBrowser
//
//  Created by xiaoyuan on 05/08/2014.
//  Copyright © 2014 xiaoyuan. All rights reserved.
//

#import "OSFileCollectionViewController.h"
#import "OSFileCollectionViewCell.h"
#import "OSFileCollectionViewFlowLayout.h"
#import "DirectoryWatcher.h"
#import "OSFileManager.h"
#import "OSFileAttributeItem.h"
#import "UIScrollView+NoDataExtend.h"
#import "OSFileBottomHUD.h"
#import "NSString+OSFile.h"
#import "UIViewController+XYExtensions.h"
#import "UIImage+XYImage.h"
#import "MBProgressHUD+BBHUD.h"
#import "ICSDrawerController.h"
#import "OSFileCollectionHeaderView.h"

#define dispatch_main_safe_async(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}

NSNotificationName const OSFileCollectionViewControllerOptionFileCompletionNotification = @"OptionFileCompletionNotification";
NSNotificationName const OSFileCollectionViewControllerOptionSelectedFileForCopyNotification = @"OptionSelectedFileForCopyNotification";
NSNotificationName const OSFileCollectionViewControllerOptionSelectedFileForMoveNotification = @"OptionSelectedFileForMoveNotification";

typedef NS_ENUM(NSInteger, OSFileLoadType) {
    OSFileLoadTypeCurrentDirectory,
    OSFileLoadTypeSubDirectory,
};

static NSString * const reuseIdentifier = @"OSFileCollectionViewCell";
static const CGFloat windowHeight = 49.0;

#ifdef __IPHONE_9_0
@interface OSFileCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIViewControllerPreviewingDelegate, NoDataPlaceholderDelegate, OSFileCollectionViewCellDelegate, OSFileBottomHUDDelegate, OSFileCollectionHeaderViewDelegate>
#else
@interface OSFileCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NoDataPlaceholderDelegate, OSFileCollectionViewCellDelegate, OSFileBottomHUDDelegate>
#endif

{
    NSString *_newFolderName;
}

@property (nonatomic, strong) OSFileCollectionViewFlowLayout *flowLayout;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPress;
@property (nonatomic, copy) void (^longPressCallBack)(NSIndexPath *indexPath);
@property (nonatomic, strong) NSOperationQueue *loadFileQueue;
@property (nonatomic, strong) OSFileManager *fileManager;
@property (nonatomic, strong) NSArray<NSString *> *directoryArray;
@property (nonatomic, assign) OSFileLoadType fileLoadType;
@property (nonatomic, strong) NSMutableArray<OSFileAttributeItem *> *selectedFiles;
@property (nonatomic, strong) OSFileBottomHUD *bottomHUD;
@property (nonatomic, assign) OSFileCollectionViewControllerMode mode;
@property (nonatomic, weak) UIButton *bottomTipButton;
@property (nonatomic, strong) OSFileAttributeItem *rootDirectoryItem;
@property (nonatomic, strong) NSMutableArray<DirectoryWatcher *> *directoryWatcherArray;

@end

@implementation OSFileCollectionViewController

#pragma mark *** Initializer ***

- (instancetype)initWithRootDirectory:(NSString *)path {
    return [self initWithRootDirectory:path controllerMode:OSFileCollectionViewControllerModeDefault];
}

- (instancetype)initWithRootDirectory:(NSString *)path controllerMode:(OSFileCollectionViewControllerMode)mode {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.fileLoadType = OSFileLoadTypeSubDirectory;
        self.mode = mode;
        _hideDisplayFiles = YES;
        self.rootDirectoryItem = [OSFileAttributeItem fileWithPath:path hideDisplayFiles:_hideDisplayFiles error:nil];
        [self commonInit];
        
    }
    return self;
}

- (instancetype)initWithDirectoryArray:(NSArray *)directoryArray {
    return [self initWithDirectoryArray:directoryArray controllerMode:OSFileCollectionViewControllerModeDefault];
}

- (instancetype)initWithDirectoryArray:(NSArray *)directoryArray controllerMode:(OSFileCollectionViewControllerMode)mode {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.fileLoadType = OSFileLoadTypeCurrentDirectory;
        self.mode = mode;
        _hideDisplayFiles = YES;
        self.directoryArray = directoryArray;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _fileManager = [OSFileManager defaultManager];
    _loadFileQueue = [NSOperationQueue new];
    _directoryWatcherArray = [NSMutableArray array];
    
    [self initWatcherFolder];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotateToInterfaceOrientation) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(optionFileCompletion:) name:OSFileCollectionViewControllerOptionFileCompletionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(collectionReLayoutStyle) name:OSFileCollectionLayoutStyleDidChangeNotification object:nil];
    
    [self setupNavigationBar];

}

/// 初始化需要监听的目录
- (void)initWatcherFolder {
    __weak typeof(self) weakSelf = self;
    NSMutableArray *needWatchPathArray = [NSMutableArray array];
    
    if (self.rootDirectoryItem.path.length) {
        [needWatchPathArray addObject:self.rootDirectoryItem.path];
    }
    
    NSString *documentPath = [NSString getDocumentPath];
    if (![self.rootDirectoryItem.path isEqualToString:documentPath]) {
        [needWatchPathArray addObject:documentPath];
    }
    
    for (NSString *path in self.directoryArray) {
        NSUInteger foundIdx = [needWatchPathArray indexOfObjectPassingTest:^BOOL(NSString *  _Nonnull needWatchPath, NSUInteger idx, BOOL * _Nonnull stop) {
            return [path isEqualToString:needWatchPath];
        }];
        if (foundIdx == NSNotFound) {
            [needWatchPathArray addObject:path];
        }
    }
    
    for (NSString *path in needWatchPathArray) {
        DirectoryWatcher *watcher = [DirectoryWatcher watchFolderWithPath:path directoryDidChange:^(DirectoryWatcher *folderWatcher) {
            [weakSelf reloadFiles];
        }];
        if (watcher) {
            [self.directoryWatcherArray addObject:watcher];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupViews];
    __weak typeof(self) weakSelf = self;
    [self reloadFilesWithCallBack:^{
        [weakSelf showBottomTip];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self check3DTouch];
    
    if ((self.mode == OSFileCollectionViewControllerModeCopy ||
         self.mode == OSFileCollectionViewControllerModeMove) &&
        self.rootDirectoryItem) {
        [self bottomTipButton].hidden = NO;
    }
    else {
        [self bottomTipButton].hidden = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.bottomHUD hideHudCompletion:^(OSFileBottomHUD *hud) {
        
        self.navigationItem.rightBarButtonItem.enabled = YES;
        _bottomHUD = nil;
        UIEdgeInsets contentInset = self.collectionView.contentInset;
        contentInset.bottom = 20.0;
        self.collectionView.contentInset = contentInset;
    }];
    if (self.mode == OSFileCollectionViewControllerModeEdit) {
        [self rightBarButtonClick];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self bottomTipButton].hidden = YES;
}

- (void)dealloc {
    self.bottomHUD = nil;
    [_bottomTipButton removeFromSuperview];
    _bottomTipButton = nil;
    self.directoryArray = nil;
    for (DirectoryWatcher *watcher in self.directoryWatcherArray) {
        [watcher invalidate];
    }
    self.directoryWatcherArray = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupViews {
    self.view.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    
    [self.view addSubview:self.collectionView];
    [self makeCollectionViewConstr];
    [self setupNodataView];
}

- (void)setupNodataView {
    __weak typeof(self) weakSelf = self;
    
    self.collectionView.noDataPlaceholderDelegate = self;
    self.collectionView.customNoDataView = ^UIView * _Nonnull{
        if (weakSelf.collectionView.xy_loading) {
            UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [activityView startAnimating];
            return activityView;
        }
        else {
            return nil;
        }
        
    };
    
    if ([self.rootDirectoryItem isDownloadBrowser]) {
        self.collectionView.noDataDetailTextLabelBlock = ^(UILabel * _Nonnull detailTextLabel) {
            NSAttributedString *string = [weakSelf noDataDetailLabelAttributedString];
            if (!string.length) {
                return;
            }
            detailTextLabel.backgroundColor = [UIColor clearColor];
            detailTextLabel.font = [UIFont systemFontOfSize:17.0];
            detailTextLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
            detailTextLabel.textAlignment = NSTextAlignmentCenter;
            detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
            detailTextLabel.numberOfLines = 0;
            detailTextLabel.attributedText = string;
        };
        self.collectionView.noDataImageViewBlock = ^(UIImageView * _Nonnull imageView) {
            imageView.backgroundColor = [UIColor clearColor];
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            imageView.userInteractionEnabled = NO;
            imageView.image = [weakSelf noDataImageViewImage];
            
        };
        
        self.collectionView.noDataReloadButtonBlock = ^(UIButton * _Nonnull reloadButton) {
            reloadButton.backgroundColor = [UIColor clearColor];
            reloadButton.layer.borderWidth = 0.5;
            reloadButton.layer.borderColor = [UIColor colorWithRed:49/255.0 green:194/255.0 blue:124/255.0 alpha:1.0].CGColor;
            reloadButton.layer.cornerRadius = 2.0;
            [reloadButton.layer setMasksToBounds:YES];
            [reloadButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            [reloadButton setAttributedTitle:[weakSelf noDataReloadButtonAttributedStringWithState:UIControlStateNormal] forState:UIControlStateNormal];
        };
        
        self.collectionView.noDataButtonEdgeInsets = UIEdgeInsetsMake(20, 100, 11, 100);
    }
    self.collectionView.noDataTextLabelBlock = ^(UILabel * _Nonnull textLabel) {
        NSAttributedString *string = [weakSelf noDataTextLabelAttributedString];
        if (!string.length) {
            return;
        }
        textLabel.backgroundColor = [UIColor clearColor];
        textLabel.font = [UIFont systemFontOfSize:27.0];
        textLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
        textLabel.textAlignment = NSTextAlignmentCenter;
        textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        textLabel.numberOfLines = 0;
        textLabel.attributedText = string;
    };
    
    self.collectionView.noDataTextEdgeInsets = UIEdgeInsetsMake(20, 0, 20, 0);
    
    
}

#pragma mark *** NavigationBar ***

- (void)setupNavigationBar {
    self.navigationItem.title = @"文件浏览";
    if (@available(iOS 11.0, *)) {
        if (!self.directoryArray.count) {
            // 导航大标题, 上滑到顶部时动态切换大小标题样式 (导航栏高度UINavigationBar = 44/96)
            self.navigationController.navigationBar.prefersLargeTitles = YES;
            // 自动模式,依赖于上一个item的设置; 上一个item设置为自动并且当前导航栏prefersLargeTitles=YES,则显示大标题样式;
            self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
            // prefersLargeTitles=YES,滚动到顶部时,当前总是显示大标题样式
            //        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
            // prefersLargeTitles=YES,滚动到顶部时,当前也总不会显示大标题样式
            //        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
        }
        
        
    }
    if (self.rootDirectoryItem) {
        self.navigationItem.title = self.rootDirectoryItem.displayName;
    }
    
    // 如果数组中只有下载文件夹和iTunes文件夹，就不能显示编辑
    BOOL displayEdit = YES;
    if (self.directoryArray) {
        NSIndexSet *set = [self.files indexesOfObjectsPassingTest:^BOOL(OSFileAttributeItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
            return [item isRootDirectory];
        }];
        if (set.count == self.directoryArray.count) {
            displayEdit = NO;
        }
        if ( self.mode == OSFileCollectionViewControllerModeCopy ||
            self.mode == OSFileCollectionViewControllerModeMove) {
            displayEdit = YES;
        }
    }
    if (displayEdit && self.files.count) {
        if (!self.navigationItem.rightBarButtonItem) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"编辑" style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonClick)];
        }
        else {
            self.navigationItem.rightBarButtonItem.title = @"编辑";
        }
        
        switch (self.mode) {
            case OSFileCollectionViewControllerModeDefault: {
                self.navigationItem.rightBarButtonItem.title = @"编辑";
                break;
            }
            case OSFileCollectionViewControllerModeEdit: {
                self.navigationItem.rightBarButtonItem.title = @"完成";
                break;
            }
            case OSFileCollectionViewControllerModeCopy:
            case OSFileCollectionViewControllerModeMove: {
                self.navigationItem.rightBarButtonItem.title = @"取消";
                break;
            }
            default:
                break;
        }
    }
}

- (void)rightBarButtonClick {
    [self updateMode];
    switch (self.mode) {
        case OSFileCollectionViewControllerModeEdit: {
            [self leaveEditModeAction];
            break;
        }
        case OSFileCollectionViewControllerModeDefault: {
            [self enterEditModeAction];
            break;
        }
        case OSFileCollectionViewControllerModeCopy: {
            [self copyModeAction];
            break;
        }
        case OSFileCollectionViewControllerModeMove: {
            [self moveModeAction];
            break;
        }
        default:
            break;
    }
    
}

- (void)updateMode {
    self.collectionView.allowsMultipleSelection = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    if (self.mode == OSFileCollectionViewControllerModeDefault)  {
        self.mode = OSFileCollectionViewControllerModeEdit;
    }
    else if (self.mode == OSFileCollectionViewControllerModeEdit) {
        self.mode = OSFileCollectionViewControllerModeDefault;
    }
    
    
}

- (void)enterEditModeAction {
    for (OSFileAttributeItem *item in self.files) {
        item.status = OSFileAttributeItemStatusDefault;
    }
    [self.collectionView reloadData];
    self.navigationItem.rightBarButtonItem.title = @"编辑";
    
    [self.bottomHUD hideHudCompletion:^(OSFileBottomHUD *hud) {
        
        self.navigationItem.rightBarButtonItem.enabled = YES;
        _bottomHUD = nil;
        UIEdgeInsets contentInset = self.collectionView.contentInset;
        contentInset.bottom = 20.0;
        self.collectionView.contentInset = contentInset;
    }];
}

- (void)leaveEditModeAction {
    self.collectionView.allowsMultipleSelection = YES;
    for (OSFileAttributeItem *item in self.files) {
        item.status = OSFileAttributeItemStatusEdit;
    }
    [self.collectionView reloadData];
    self.navigationItem.rightBarButtonItem.title = @"完成";
    
    [self.bottomHUD showHUDWithFrame:CGRectMake(0, self.view.frame.size.height - windowHeight, self.view.frame.size.width, windowHeight) completion:^(OSFileBottomHUD *hud) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
        UIEdgeInsets contentInset = self.collectionView.contentInset;
        contentInset.bottom = contentInset.bottom + hud.frame.size.height;
        self.collectionView.contentInset = contentInset;
    }];
}

- (void)copyModeAction {
    [self backButtonClick];
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)moveModeAction {
    [self backButtonClick];
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

#pragma mark *** Load file ***

- (void)loadFileWithDirectoryArray:(NSArray<NSString *> *)directoryArray completion:(void (^)(NSArray *fileItems))completion {
    [_loadFileQueue cancelAllOperations];
    [_loadFileQueue addOperationWithBlock:^{
        NSMutableArray *array = @[].mutableCopy;
        [directoryArray enumerateObjectsUsingBlock:^(NSString * _Nonnull fullPath, NSUInteger idx, BOOL * _Nonnull stop) {
            NSError *error = nil;
            OSFileAttributeItem *model = [OSFileAttributeItem fileWithPath:fullPath hideDisplayFiles:_hideDisplayFiles error:&error];
            if (model) {
                model.isRootDirectory = YES;
                if (self.mode == OSFileCollectionViewControllerModeEdit) {
                    model.status = OSFileAttributeItemStatusEdit;
                }
                [array addObject:model];
            }
        }];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(array);
            });
        }
        
    }];
    
    
}

- (void)loadFileWithDirectoryItem:(OSFileAttributeItem *)directoryItem completion:(void (^)(NSArray *fileItems))completion {
    [_loadFileQueue cancelAllOperations];
    [_loadFileQueue addOperationWithBlock:^{
        NSMutableArray *array = @[].mutableCopy;
        [directoryItem.subFiles enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *fullPath = [directoryItem.path stringByAppendingPathComponent:obj];
            NSError *error = nil;
            OSFileAttributeItem *model = [OSFileAttributeItem fileWithPath:fullPath hideDisplayFiles:_hideDisplayFiles error:&error];
            if (model) {
                if (self.mode == OSFileCollectionViewControllerModeEdit) {
                    model.status = OSFileAttributeItemStatusEdit;
                }
                
                [array addObject:model];
            }
            
        }];
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(array);
            });
        }
    }];
}

- (void)reloadFiles {
    [self reloadFilesWithCallBack:NULL];
}

- (void)reloadFilesWithCallBack:(void (^)(void))callBack {
    self.files = nil;
    self.collectionView.xy_loading = YES;
    __weak typeof(self) weakSelf = self;
    void (^ reloadCallBack)(NSArray *fileItems) = ^ (NSArray *fileItems){
        weakSelf.files = fileItems.copy;
        [weakSelf reloadCollectionData];
        if (callBack) {
            callBack();
        }
        self.collectionView.xy_loading = NO;
    };
    
    switch (self.fileLoadType) {
        case OSFileLoadTypeCurrentDirectory: {
            [self loadFileWithDirectoryArray:self.directoryArray completion:reloadCallBack];
            break;
        }
        case OSFileLoadTypeSubDirectory: {
            NSError *error = nil;
            [self.rootDirectoryItem reloadFileWithError:&error];
            [self loadFileWithDirectoryItem:self.rootDirectoryItem completion:reloadCallBack];
            break;
        }
        default:
            break;
    }
    
}

- (void)reloadCollectionData {
    [self.collectionView reloadData];
    [self setupNavigationBar];
}

#pragma mark *** check3DTouch ***

- (void)check3DTouch {
    /// 检测是否有3d touch 功能
    if (@available(iOS 9.0, *)) {
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
#pragma mark *** 3D Touch Delegate ***

#ifdef __IPHONE_9_0
- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    // 需要将location在self.view上的坐标转换到tableView上，才能从tableView上获取到当前indexPath
    CGPoint targetLocation = [self.view convertPoint:location toView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:targetLocation];
    UIViewController *vc = [self previewControllerByIndexPath:indexPath];
    if ([vc isKindOfClass:[OSPreviewViewController class]]) {
        OSPreviewViewController *pvc = (OSPreviewViewController *)vc;
        pvc.currentPreviewItemIndex = indexPath.row;
    }
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

#pragma mark *** UICollectionViewDataSource ***

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.files.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    OSFileCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.fileModel = self.files[indexPath.row];
    if (cell.fileModel.status == OSFileAttributeItemStatusChecked) {
        [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
    else {
        [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
    cell.delegate = self;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.mode == OSFileCollectionViewControllerModeEdit) {
        OSFileAttributeItem *item = self.files[indexPath.row];
        item.status = OSFileAttributeItemStatusChecked;
        [self addSelectedFile:item];
        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        });
    } else {
        UIViewController *vc = [self previewControllerByIndexPath:indexPath];
        [self showDetailController:vc atIndexPath:indexPath];
        if ([vc isKindOfClass:[OSPreviewViewController class]]) {
            OSPreviewViewController *pvc = (OSPreviewViewController *)vc;
            pvc.currentPreviewItemIndex = indexPath.item;
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.mode == OSFileCollectionViewControllerModeEdit) {
        OSFileAttributeItem *item = self.files[indexPath.row];
        item.status = OSFileAttributeItemStatusEdit;
        [self.selectedFiles removeObject:item];
        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [collectionView deselectItemAtIndexPath:indexPath animated:YES];
        });
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        OSFileCollectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:OSFileCollectionHeaderViewDefaultIdentifier forIndexPath:indexPath];
        headerView.delegate = self;
        return headerView;
    }
    
    return nil;
}


#pragma mark *** Show detail controller ***

- (void)showDetailController:(UIViewController *)viewController parentPath:(NSString *)parentPath {
    if (!viewController) {
        return;
    }
//    if ([viewController isKindOfClass:[OSFileCollectionViewController class]]) {
//        OSFileCollectionViewController *vc = (OSFileCollectionViewController *)viewController;
//        [self.navigationController showViewController:vc sender:self];
//    }
//    else {
//
//        viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonClick)];
//        [self.navigationController showViewController:viewController sender:self];
//    }
    [self.navigationController showViewController:viewController sender:self];
}

- (void)showDetailController:(UIViewController *)viewController atIndexPath:(NSIndexPath *)indexPath {
    NSString *newPath = self.files[indexPath.row].path;
    if (!newPath.length) {
        return;
    }
    [self showDetailController:viewController parentPath:newPath];
}

- (void)backButtonClick {
    UIViewController *rootViewController = (UINavigationController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    [self backButtonClickWithRootViewController:rootViewController];
}

- (void)backButtonClickWithRootViewController:(UIViewController *)rootViewController {
    if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nac = (UINavigationController *)rootViewController;
        if (self.presentedViewController || nac.topViewController.presentedViewController) {
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    else if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabc = (UITabBarController *)rootViewController;
        UINavigationController *nac = tabc.selectedViewController;
        if ([nac isKindOfClass:[UINavigationController class]]) {
            if (self.presentedViewController || nac.presentedViewController) {
                [self dismissViewControllerAnimated:YES completion:nil];
            } else {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
        
    }
    else if ([rootViewController isKindOfClass:NSClassFromString(@"ICSDrawerController")]) {
        ICSDrawerController *vc = (ICSDrawerController *)rootViewController;
        [self backButtonClickWithRootViewController:vc.ics_visibleViewController];
    }
}

- (UIViewController *)previewControllerWithFilePath:(NSString *)filePath {
    OSFileAttributeItem *newItem = [self getFileItemByPath:filePath];
    return [self previewControllerWithFileItem:newItem];
}

- (UIViewController *)previewControllerWithFileItem:(OSFileAttributeItem *)newItem {
    if (newItem) {
        BOOL isDirectory;
        BOOL fileExists = [[NSFileManager defaultManager ] fileExistsAtPath:newItem.path isDirectory:&isDirectory];
        UIViewController *vc = nil;
        if (fileExists) {
            if (newItem.isDirectory) {
                /// 如果当前界面是OSFileCollectionViewControllerModeCopy，那么下一个界面也要是同样的模式
                OSFileCollectionViewControllerMode mode = OSFileCollectionViewControllerModeDefault;
                if (self.mode == OSFileCollectionViewControllerModeCopy ||
                    self.mode == OSFileCollectionViewControllerModeMove) {
                    mode = self.mode;
                }
                vc = [[OSFileCollectionViewController alloc] initWithRootDirectory:newItem.path controllerMode:mode];
                if (self.mode == OSFileCollectionViewControllerModeCopy ||
                    self.mode == OSFileCollectionViewControllerModeMove) {
                    OSFileCollectionViewController *viewController = (OSFileCollectionViewController *)vc;
                    viewController.selectedFiles = self.selectedFiles.mutableCopy;
                }
                
            }
            else if ([OSFilePreviewViewController canOpenFile:newItem.path]) {
                vc = [[OSFilePreviewViewController alloc] initWithFileItem:newItem];
            }
            else if ([OSPreviewViewController canPreviewItem:[NSURL fileURLWithPath:newItem.path]]) {
                OSPreviewViewController *preview= [[OSPreviewViewController alloc] init];
                preview.dataSource = self;
                preview.delegate = self;
                vc = preview;
            }
            else {
                [self.view bb_showMessage:@"无法识别的文件"];
            }
        }
        return vc;
    }
    return nil;
}

- (OSFileAttributeItem *)getFileItemByPath:(NSString *)path {
    NSUInteger foundIdx = [self.files indexOfObjectPassingTest:^BOOL(OSFileAttributeItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL res = [obj.path isEqualToString:path];
        if (res) {
            *stop = YES;
        }
        return res;
    }];
    
    OSFileAttributeItem *newItem = nil;
    if (foundIdx != NSNotFound) {
        newItem = self.files[foundIdx];
    }
    else {
        NSError *error = nil;
        newItem = [OSFileAttributeItem fileWithPath:path error:&error];
    }
    return newItem;
}

- (UIViewController *)previewControllerByIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath || !self.files.count) {
        return nil;
    }
    OSFileAttributeItem *newItem = self.files[indexPath.row];
    return [self previewControllerWithFileItem:newItem];
}

#pragma mark *** QLPreviewControllerDataSource ***

- (BOOL)previewController:(QLPreviewController *)controller shouldOpenURL:(NSURL *)url forPreviewItem:(id <QLPreviewItem>)item {
    
    return YES;
}

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return self.files.count;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger) index {
    NSString *newPath = self.files[index].path;
    
    return [NSURL fileURLWithPath:newPath];
}

#pragma mark *** QLPreviewControllerDelegate ***

- (CGRect)previewController:(QLPreviewController *)controller frameForPreviewItem:(id <QLPreviewItem>)item inSourceView:(UIView * _Nullable * __nonnull)view {
    return self.view.frame;
}

#pragma mark *** Actions ***

- (UILongPressGestureRecognizer *)longPress {
    
    if (!_longPress) {
        _longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(showPeek:)];
        [self.view addGestureRecognizer:_longPress];
    }
    return _longPress;
}

- (void)showPeek:(UILongPressGestureRecognizer *)longPress {
    if (longPress.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [longPress locationInView:self.collectionView];
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
        
        if (self.longPressCallBack) {
            self.longPressCallBack(indexPath);
        }
        
        self.longPress.enabled = NO;
        UIViewController *vc = [self previewControllerByIndexPath:indexPath];
        [self showDetailController:vc atIndexPath:indexPath];
    }
}

#pragma mark *** Layout ***

- (void)makeCollectionViewConstr {
    
    if (@available(iOS 11.0, *)) {
        NSLayoutConstraint *top = [self.collectionView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor];
        NSLayoutConstraint *left = [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor];
        NSLayoutConstraint *right = [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor];
        NSLayoutConstraint *bottom = [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor];
        [NSLayoutConstraint activateConstraints:@[top, left, right, bottom]];
    } else {
        NSDictionary *views = NSDictionaryOfVariableBindings(_collectionView);
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_collectionView]|" options:0 metrics:nil views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_collectionView]|" options:0 metrics:nil views:views]];
    }
}

#pragma mark *** Setter getter ***

- (void)setHideDisplayFiles:(BOOL)hideDisplayFiles {
    if (_hideDisplayFiles == hideDisplayFiles) {
        return;
    }
    _hideDisplayFiles = hideDisplayFiles;
    [self reloadFiles];
    
}


- (OSFileBottomHUD *)bottomHUD {
    if (!_bottomHUD) {
        _bottomHUD = [[OSFileBottomHUD alloc] initWithItems:@[
                                                              [[OSFileBottomHUDItem alloc] initWithTitle:@"全选" image:nil],
                                                              [[OSFileBottomHUDItem alloc] initWithTitle:@"复制" image:nil],
                                                              [[OSFileBottomHUDItem alloc] initWithTitle:@"移动" image:nil],
                                                              [[OSFileBottomHUDItem alloc] initWithTitle:@"删除" image:nil],
                                                              [[OSFileBottomHUDItem alloc] initWithTitle:@"文件夹" image:nil],
                                                              ] toView:self.view];
        _bottomHUD.delegate = self;
        _bottomHUD.backgroundColor = [UIColor colorWithRed:36/255.0 green:41/255.0 blue:46/255.0 alpha:1.0];
    }
    return _bottomHUD;
}


- (OSFileCollectionViewFlowLayout *)flowLayout {
    
    if (_flowLayout == nil) {
        
        OSFileCollectionViewFlowLayout *layout = [OSFileCollectionViewFlowLayout new];
        _flowLayout = layout;
        layout.itemSpacing = 20.0;
        layout.lineSpacing = 20.0;
        
        [self updateCollectionViewFlowLayout:_flowLayout];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.sectionsStartOnNewLine = NO;
        layout.headerSize = CGSizeMake(self.view.bounds.size.width, 44.0);
    }
    return _flowLayout;
}

- (UICollectionView *)collectionView {
    if (_collectionView == nil) {
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.flowLayout];
        collectionView.dataSource = self;
        collectionView.delegate = self;
        collectionView.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
        [collectionView registerClass:[OSFileCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
        [collectionView registerClass:[OSFileCollectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:OSFileCollectionHeaderViewDefaultIdentifier];
        _collectionView = collectionView;
        _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        if (![OSFileCollectionViewFlowLayout singleItemOnLine] || ![[OSFileCollectionViewFlowLayout singleItemOnLine] isEqual:@(YES)]) {
            UIEdgeInsets inset = _collectionView.contentInset;
            inset.left = 20.0;
            inset.right = 20.0;
            inset.bottom = 20.0;
            _collectionView.contentInset = inset;
        }
        else {
          _collectionView.contentInset = UIEdgeInsetsMake(0, 0, 20.0, 0);
        }
       
    }
    return _collectionView;
}


- (UIButton *)bottomTipButton {
    if (!_bottomTipButton) {
        UIButton *bottomTipButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _bottomTipButton = bottomTipButton;
        [self.view addSubview:bottomTipButton];
        bottomTipButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[bottomTipButton]|" options:kNilOptions metrics:nil views:@{@"bottomTipButton": bottomTipButton}]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[bottomTipButton(==49.0)]|" options:kNilOptions metrics:nil views:@{@"bottomTipButton": bottomTipButton}]];
        _bottomTipButton.backgroundColor = [UIColor colorWithRed:78/255.0 green:93/255.0 blue:115/255.0 alpha:1.0];
        [bottomTipButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        bottomTipButton.titleLabel.numberOfLines = 3;
        bottomTipButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        bottomTipButton.titleLabel.minimumScaleFactor = 0.5;
        bottomTipButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [_bottomTipButton addTarget:self action:@selector(chooseCompletion) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _bottomTipButton;
}

- (NSMutableArray<OSFileAttributeItem *> *)selectedFiles {
    if (!_selectedFiles) {
        _selectedFiles = @[].mutableCopy;
    }
    return _selectedFiles;
}


- (void)addSelectedFile:(OSFileAttributeItem *)item {
    if (![self.selectedFiles containsObject:item] && !item.isRootDirectory) {
        [self.selectedFiles addObject:item];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

- (void)showBottomTip {
    if ((self.mode != OSFileCollectionViewControllerModeCopy &&
         self.mode != OSFileCollectionViewControllerModeMove) ||
        !self.rootDirectoryItem) {
        _bottomTipButton.hidden = YES;
        return;
    }
    
    _bottomTipButton.hidden = NO;
    NSString *string = @"复制";
    if (self.mode == OSFileCollectionViewControllerModeMove) {
        string = @"移动";
    }
    [_bottomTipButton setTitle:[NSString stringWithFormat:@"【%@到(%@)目录】", string, self.rootDirectoryItem.displayName] forState:UIControlStateNormal];
    /// 检测已选择的文件是否在当前文件中，如果在就提示用户
    NSMutableArray *containFileArray = @[].mutableCopy;
    if (self.files) {
        [self.selectedFiles enumerateObjectsUsingBlock:^(OSFileAttributeItem * _Nonnull seleFile, NSUInteger idx, BOOL * _Nonnull stop) {
            NSUInteger foundIdx = [self.files indexOfObjectPassingTest:^BOOL(OSFileAttributeItem * _Nonnull file, NSUInteger idx, BOOL * _Nonnull stop) {
                BOOL res = NO;
                if ([seleFile.path isEqualToString:file.path]) {
                    res = YES;
                    *stop = YES;
                }
                return res;
            }];
            if (foundIdx != NSNotFound) {
                [containFileArray addObject:seleFile.displayName];
            }
        }];
        
        if (containFileArray.count) {
            string = [containFileArray componentsJoinedByString:@","];
            string = [NSString stringWithFormat:@"请确认：已存在的文件会被替换:(%@)", string];
            [_bottomTipButton setTitle:string forState:UIControlStateNormal];
        }
    }
    
    [self.view bringSubviewToFront:_bottomTipButton];
}

/// 将选择的文件拷贝到目标目录中
- (void)chooseCompletion {
    __weak typeof(&*self) weakSelf = self;
    [self copyFiles:self.selectedFiles toRootDirectory:self.rootDirectoryItem.path completionHandler:^(void) {
        __strong typeof(&*weakSelf) self = weakSelf;
        [self.selectedFiles removeAllObjects];
        [[NSNotificationCenter defaultCenter] postNotificationName:OSFileCollectionViewControllerOptionFileCompletionNotification object:nil userInfo:@{@"OSFileCollectionViewControllerMode": @(weakSelf.mode)}];
        [self backButtonClick];
    }];
    
}
#pragma mark *** OSFileBottomHUDDelegate ***

- (void)fileBottomHUD:(OSFileBottomHUD *)hud didClickItem:(OSFileBottomHUDItem *)item {
    switch (item.buttonIdx) {
        case 0: { // 全选
            [self selectAllFilesWithHUDItem:item];
            break;
        }
        case 1: { // 复制
            if (!self.selectedFiles.count) {
                [self.view bb_showMessage:@"请选择需要复制的文件"];
            }
            else {
                [self chooseDesDirectoryToCopy];
            }
            
            break;
        }
        case 2: { // 移动
            if (!self.selectedFiles.count) {
                [self.view bb_showMessage:@"请选择需要移动的文件"];
            }
            else {
                [self chooseDesDirectoryToMove];
            }
            break;
        }
        case 3: { // 删除
            if (!self.selectedFiles.count) {
                [self.view bb_showMessage:@"请选择需要删除的文件"];
            }
            else {
                [self deleteSelectFiles];
            }
            break;
        }
        case 4: { // 新建文件夹
            [self createNewFolderPath];
            break;
        }
        default:
            break;
    }
}

- (void)alertViewTextFieldtextChange:(UITextField *)tf {
    _newFolderName = tf.text;
}

- (void)createNewFolderPath {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"新建文件" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"请输入文件夹名称";
        [textField addTarget:self action:@selector(alertViewTextFieldtextChange:) forControlEvents:UIControlEventEditingChanged];
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        if ([_newFolderName containsString:@"/"]) {
            [self.view bb_showMessage:@"名称中包含不符合的字符"];
            return;
        }
        
        NSString *currentDirectory = self.rootDirectoryItem.path;
        NSString *newPath = [currentDirectory stringByAppendingPathComponent:_newFolderName];
        BOOL res = [[NSFileManager defaultManager] fileExistsAtPath:newPath];
        if (res) {
            [self.view bb_showMessage:@"存在同名的文件"];
            return;
        }
        NSError *moveError = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:newPath withIntermediateDirectories:YES attributes:nil error:&moveError];
        if (!moveError) {
            // 将选中的文件移动到创建的目录中
            __weak typeof(&*self) weakSelf = self;
            [self copyFiles:self.selectedFiles toRootDirectory:newPath completionHandler:^(void) {
                __strong typeof(&*weakSelf) self = weakSelf;
                [self.selectedFiles removeAllObjects];
                [[NSNotificationCenter defaultCenter] postNotificationName:OSFileCollectionViewControllerOptionFileCompletionNotification object:nil userInfo:@{@"OSFileCollectionViewControllerMode": @(weakSelf.mode)}];
                [self reloadFiles];
            }];
        } else {
            NSLog(@"%@", moveError.localizedDescription);
        }
        _newFolderName = nil;
    }]];
    [[UIViewController xy_topViewController] presentViewController:alert animated:true completion:nil];
}

/// 选择文件最终复制的目标目录
- (void)chooseDesDirectoryToCopy {
    [self optionSelectedFiles:OSFileCollectionViewControllerModeCopy];
    
}

- (void)chooseDesDirectoryToMove {
    [self optionSelectedFiles:OSFileCollectionViewControllerModeMove];
}

- (void)optionSelectedFiles:(OSFileCollectionViewControllerMode)mode {
    switch (mode) {
        case OSFileCollectionViewControllerModeMove:
            [[NSNotificationCenter defaultCenter] postNotificationName:OSFileCollectionViewControllerOptionSelectedFileForMoveNotification object:self userInfo:@{@"OSSelectedFilesKey": self.selectedFiles?:@[]}];
            break;
        case OSFileCollectionViewControllerModeCopy:
            [[NSNotificationCenter defaultCenter] postNotificationName:OSFileCollectionViewControllerOptionSelectedFileForCopyNotification object:self userInfo:@{@"OSSelectedFilesKey": self.selectedFiles?:@[]}];
            break;
        default:
            break;
    }
    
    if (self.class.fileOperationDelegate && [self.class.fileOperationDelegate respondsToSelector:@selector(fileCollectionViewController:selectedFiles:optionMode:)]) {
        [self.class.fileOperationDelegate fileCollectionViewController:self selectedFiles:self.selectedFiles optionMode:mode];
    }
    else {
        NSArray *desDirectors = nil;
        if (self.class.fileOperationDelegate && [self.class.fileOperationDelegate respondsToSelector:@selector(desDirectorsForOption:selectedFiles:fileCollectionViewController:)]) {
            desDirectors = [self.class.fileOperationDelegate desDirectorsForOption:mode selectedFiles:self.selectedFiles fileCollectionViewController:self];
        }
        if (!desDirectors.count) {
            desDirectors = @[
                             [NSString getICloudCacheFolder],
                             [NSString getDocumentPath]];
        }
        OSFileCollectionViewController *vc = [[OSFileCollectionViewController alloc] initWithDirectoryArray:desDirectors controllerMode:mode];
        UINavigationController *nac = [[[self.navigationController class] alloc] initWithRootViewController:vc];
        vc.selectedFiles = self.selectedFiles.mutableCopy;
        [self showDetailViewController:nac sender:self];
    }
}


- (void)deleteSelectFiles {
    if (!self.selectedFiles.count) {
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确定删除吗" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        for (OSFileAttributeItem *item in self.selectedFiles ) {
            NSString *currentPath = item.path;
            NSError *error = nil;
            BOOL isSuccess = [[NSFileManager defaultManager] removeItemAtPath:currentPath error:&error];
            if (!isSuccess && error) {
                [[[UIAlertView alloc] initWithTitle:@"Remove error" message:nil delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil] show];
            }
        }
        
        [self reloadFiles];
        
    }]];
    [[UIViewController xy_topViewController] presentViewController:alert animated:true completion:nil];
}

- (void)selectAllFilesWithHUDItem:(OSFileBottomHUDItem *)item {
    BOOL selectedAll = YES;
    if ([[item titleForState:UIControlStateNormal] isEqualToString:@"全选"]) {
        [item setTitle:@"取消全选" state:UIControlStateNormal];
        [self.selectedFiles removeAllObjects];
        for (OSFileAttributeItem *item in self.files) {
            [self addSelectedFile:item];
        }
        selectedAll = YES;
    }
    else {
        [item setTitle:@"全选" state:UIControlStateNormal];
        [self.selectedFiles removeAllObjects];
        selectedAll = NO;
    }
    
    [self.files enumerateObjectsUsingBlock:^(OSFileAttributeItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!selectedAll) {
            obj.status = OSFileAttributeItemStatusEdit;
        }
        else {
            obj.status = OSFileAttributeItemStatusChecked;
        }
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
        if (obj.status == OSFileAttributeItemStatusChecked) {
            [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        }
        else {
            [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
        }
        
    }];
    [self reloadCollectionData];
}

#pragma mark *** OSFileCollectionViewCellDelegate ***

- (void)fileCollectionViewCell:(OSFileCollectionViewCell *)cell fileAttributeChange:(OSFileAttributeItem *)fileModel {
    NSUInteger foudIdx = [self.files indexOfObject:fileModel];
    if (foudIdx != NSNotFound) {
        OSFileAttributeItem *item = [OSFileAttributeItem fileWithPath:fileModel.path];
        NSMutableArray *files = self.files.mutableCopy;
        [files replaceObjectAtIndex:foudIdx withObject:item];
        self.files = files;
        [self reloadCollectionData];
    }
}

- (void)fileCollectionViewCell:(OSFileCollectionViewCell *)cell needCopyFile:(OSFileAttributeItem *)fileModel {
    [self.selectedFiles removeAllObjects];
    [self addSelectedFile:fileModel];
    [self chooseDesDirectoryToCopy];
}

- (void)fileCollectionViewCell:(OSFileCollectionViewCell *)cell needDeleteFile:(OSFileAttributeItem *)fileModel {
    NSError *error = nil;
    BOOL res = [[NSFileManager defaultManager] removeItemAtPath:fileModel.path error:&error];
    if (!res || error) {
        [self.view bb_showMessage:[NSString stringWithFormat:@"删除出错%@", error.localizedDescription]];
    }
    [self reloadCollectionData];
}

#pragma mark *** Notification ***
/// 文件操作文件，比如复制、移动文件完成
- (void)optionFileCompletion:(NSNotification *)notification {
    [self.selectedFiles removeAllObjects];
    self.mode = OSFileCollectionViewControllerModeDefault;
    [self reloadFiles];
}

#pragma mark *** OSFileCollectionHeaderViewDelegate ***

- (void)collectionReLayoutStyle {
    
    [self updateCollectionViewFlowLayout:_flowLayout];
    [self.files enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(OSFileAttributeItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.needReLoyoutItem = YES;
    }];
    [self.collectionView.visibleCells enumerateObjectsUsingBlock:^(__kindof OSFileCollectionViewCell * _Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
        [cell invalidateConstraints];
        [UIView animateWithDuration:0.18 animations:^{
            [cell.contentView layoutIfNeeded];
        }];
    }];
    
    [self.flowLayout invalidateLayout];
}


#pragma mark *** File operation ***

/// copy 文件
- (void)copyFiles:(NSArray<OSFileAttributeItem *> *)fileItems
  toRootDirectory:(NSString *)rootPath
completionHandler:(void (^)(void))completion {
    if (!fileItems.count) {
        return;
    }
    
    UIView *view = (UIView *)[UIApplication sharedApplication].delegate.window;
    __weak typeof(&*self) weakSelf = self;
    [view bb_showProgressHudWithActionCallBack:^(MBProgressHUD *hud) {
         __strong typeof(&*weakSelf) self = weakSelf;
        [self.fileManager cancelAllOperation];
         hud.label.text = @"已取消";
        if (completion) {
            completion();
        }
    }];
    
    [fileItems enumerateObjectsUsingBlock:^(OSFileAttributeItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSString *desPath = [rootPath stringByAppendingPathComponent:[obj.path lastPathComponent]];
        if ([desPath isEqualToString:obj.path]) {
            NSLog(@"路径相同");
            dispatch_main_safe_async(^{
                view.bb_hud.label.text = @"路径相同";
                if (completion) {
                    completion();
                }
            });
        }
        else if ([[NSFileManager defaultManager] fileExistsAtPath:desPath]) {
            dispatch_main_safe_async(^{
                view.bb_hud.label.text = @"存在相同文件，正在移除原文件";
            });
            NSError *removeError = nil;
            [[NSFileManager defaultManager] removeItemAtPath:desPath error:&removeError];
            if (removeError) {
                NSLog(@"Error: %@", removeError.localizedDescription);
            }
        }
    }];
    
    NSMutableArray *hudDetailTextArray = @[].mutableCopy;
    
    void (^hudDetailTextCallBack)(NSString *detailText, NSInteger index) = ^(NSString *detailText, NSInteger index){
        @synchronized (hudDetailTextArray) {
            [hudDetailTextArray replaceObjectAtIndex:index withObject:detailText];
        }
    };
    
    
    /// 当completionCopyNum为0 时 全部拷贝完成
    __block NSInteger completionCopyNum = fileItems.count;
    [fileItems enumerateObjectsUsingBlock:^(OSFileAttributeItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [hudDetailTextArray addObject:@(idx).stringValue];
        NSString *desPath = [rootPath stringByAppendingPathComponent:[obj.path lastPathComponent]];
        NSURL *desURL = [NSURL fileURLWithPath:desPath];
        
        void (^ progressBlock)(NSProgress *progress) = ^ (NSProgress *progress) {
            NSString *completionSize = [NSString transformedFileSizeValue:@(progress.completedUnitCount)];
            NSString *totalSize = [NSString transformedFileSizeValue:@(progress.totalUnitCount)];
            NSString *prcent = [NSString percentageString:progress.fractionCompleted];
            NSString *detailText = [NSString stringWithFormat:@"%@  %@/%@", prcent, completionSize, totalSize];
            dispatch_main_safe_async(^{
                hudDetailTextCallBack(detailText, idx);
            });
        };
        
        void (^ completionHandler)(id<OSFileOperation> fileOperation, NSError *error) = ^(id<OSFileOperation> fileOperation, NSError *error) {
            completionCopyNum--;
            NSLog(@"剩余文件个数%ld", completionCopyNum);
        };
        NSURL *orgURL = [NSURL fileURLWithPath:obj.path];
        if (self.mode == OSFileCollectionViewControllerModeCopy) {
            [_fileManager copyItemAtURL:orgURL
                                  toURL:desURL
                               progress:progressBlock
                      completionHandler:completionHandler];
        }
        else {
            [_fileManager moveItemAtURL:orgURL
                                  toURL:desURL
                               progress:progressBlock
                      completionHandler:completionHandler];
        }
        
    }];
    
    
    _fileManager.totalProgressBlock = ^(NSProgress *progress) {
        view.bb_hud.label.text = [NSString stringWithFormat:@"total:%@  %lld/%lld", [NSString percentageString:progress.fractionCompleted], progress.completedUnitCount, progress.totalUnitCount];
        view.bb_hud.progress = progress.fractionCompleted;
        @synchronized (hudDetailTextArray) {
            NSString *detailStr = [hudDetailTextArray componentsJoinedByString:@",\n"];
            view.bb_hud.detailsLabel.text = detailStr;
        }
    };
    
    [_fileManager setCurrentOperationsFinishedBlock:^{
        if (completion) {
            completion();
        }
        view.bb_hud.label.text = @"完成";
        [view.bb_hud hideAnimated:YES afterDelay:2.0];
    }];
    
}

#pragma mark *** _fileOperationDelegate ***
__weak id _fileOperationDelegate;

+ (id<OSFileCollectionViewControllerFileOptionDelegate>)fileOperationDelegate {
    return _fileOperationDelegate;
}

+ (void)setFileOperationDelegate:(id<OSFileCollectionViewControllerFileOptionDelegate>)fileOperationDelegate {
    _fileOperationDelegate = fileOperationDelegate;
}

#pragma mark *** NoDataPlaceholderDelegate ***

- (BOOL)noDataPlaceholderShouldAllowScroll:(UIScrollView *)scrollView {
    return YES;
}

- (CGPoint)contentOffsetForNoDataPlaceholder:(UIScrollView *)scrollView {
    if ([UIDevice currentDevice].orientation == UIDeviceOrientationPortrait) {
        return CGPointMake(0, 120.0);
    }
    return CGPointMake(0, 80.0);
}

- (void)noDataPlaceholderWillAppear:(UIScrollView *)scrollView {
    
}

- (void)noDataPlaceholderDidDisappear:(UIScrollView *)scrollView {
    
}

- (BOOL)noDataPlaceholderShouldFadeInOnDisplay:(UIScrollView *)scrollView {
    return YES;
}


- (NSAttributedString *)noDataDetailLabelAttributedString {
    return nil;
}

- (UIImage *)noDataImageViewImage {
    
    return [UIImage OSFileBrowserImageNamed:@"file_noData"];
}


- (NSAttributedString *)noDataReloadButtonAttributedStringWithState:(UIControlState)state {
    return [self attributedStringWithText:@"查看缓存页" color:[UIColor colorWithRed:49/255.0 green:194/255.0 blue:124/255.0 alpha:1.0] fontSize:15.0];
}

- (void)noDataPlaceholder:(UIScrollView *)scrollView didClickReloadButton:(UIButton *)button {
    if ([self.rootDirectoryItem isDownloadBrowser]) {
        self.tabBarController.selectedIndex = 1;
        self.navigationController.viewControllers = @[self.navigationController.viewControllers.firstObject];
    }
}


- (NSAttributedString *)noDataTextLabelAttributedString {
    NSString *string = nil;
    if ([self.rootDirectoryItem isDownloadBrowser]) {
        string = @"缓存完成的文件在这显示";
    }
    else if ([self.rootDirectoryItem isICloudDrive]) {
        string = @"将文件移动到此处，即可从iPhone、iPad、Mac访问";
    }
    else {
        string = @"没有文件";
    }
    return [self attributedStringWithText:string color:[UIColor grayColor] fontSize:16];;
}

- (NSAttributedString *)attributedStringWithText:(NSString *)string color:(UIColor *)color fontSize:(CGFloat)fontSize {
    NSString *text = string;
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    UIColor *textColor = color;
    
    NSMutableDictionary *attributeDict = [NSMutableDictionary new];
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.lineBreakMode = NSLineBreakByWordWrapping;
    style.alignment = NSTextAlignmentCenter;
    style.lineSpacing = 4.0;
    [attributeDict setObject:font forKey:NSFontAttributeName];
    [attributeDict setObject:textColor forKey:NSForegroundColorAttributeName];
    [attributeDict setObject:style forKey:NSParagraphStyleAttributeName];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:attributeDict];
    
    return attributedString;
    
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////
- (void)rotateToInterfaceOrientation {
    [self updateCollectionViewFlowLayout:self.flowLayout];
    /// 屏幕旋转时重新布局item
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)updateCollectionViewFlowLayout:(OSFileCollectionViewFlowLayout *)flowLayout {
    if ([OSFileCollectionViewFlowLayout singleItemOnLine] && [[OSFileCollectionViewFlowLayout singleItemOnLine] isEqual:@(YES)]) {
        flowLayout.lineItemCount = 1;
        flowLayout.lineMultiplier = 0.12;
        UIEdgeInsets contentInset = self.collectionView.contentInset;
        contentInset.left = 0.0;
        contentInset.right = 0.0;
        _collectionView.contentInset = contentInset;
    }
    else {
        UIEdgeInsets contentInset = self.collectionView.contentInset;
        contentInset.left = 20.0;
        contentInset.right = 20.0;
        _collectionView.contentInset = contentInset;
        flowLayout.lineMultiplier = 1.19;
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
            flowLayout.lineItemCount = 5;
        }
        else {
            flowLayout.lineItemCount = 3;
        }
    }
}

@end

