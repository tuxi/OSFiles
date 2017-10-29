//
//  OSFileCollectionViewController.m
//  FileDownloader
//
//  Created by Swae on 2017/10/28.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileCollectionViewController.h"
#import "OSFileCollectionViewCell.h"
#import "OSFileCollectionViewFlowLayout.h"
#import "DirectoryWatcher.h"
#import "OSFileManager.h"
#import "OSFileAttributeItem.h"
#import "FilePreviewViewController.h"
#import <UIScrollView+NoDataExtend.h>

typedef NS_ENUM(NSInteger, OSFileLoadType) {
    OSFileLoadTypeCurrentDirectory,
    OSFileLoadTypeSubDirectory,
};

static NSString * const reuseIdentifier = @"OSFileCollectionViewCell";

#ifdef __IPHONE_9_0
@interface OSFileCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIViewControllerPreviewingDelegate, NoDataPlaceholderDelegate>
#else
@interface OSFileCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NoDataPlaceholderDelegate>
#endif

{
    DirectoryWatcher *_currentFolderHelper;
    DirectoryWatcher *_documentFolderHelper;
}

@property (nonatomic, strong) OSFileCollectionViewFlowLayout *flowLayout;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPress;
@property (nonatomic, copy) void (^longPressCallBack)(NSIndexPath *indexPath);
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) NSOperationQueue *loadFileQueue;
@property (nonatomic, strong) OSFileManager *fileManager;
@property (nonatomic, strong) MBProgressHUD *hud;
@property (nonatomic, strong) NSArray *directoryArray;
@property (nonatomic, assign) OSFileLoadType fileLoadType;

@end

@implementation OSFileCollectionViewController

////////////////////////////////////////////////////////////////////////
#pragma mark - Initialize
////////////////////////////////////////////////////////////////////////

- (instancetype)initWithRootDirectory:(NSString *)path {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.fileLoadType = OSFileLoadTypeSubDirectory;
        [self commonInit];
        self.rootDirectory = path;
        
    }
    return self;
}

- (instancetype)initWithDirectoryArray:(NSArray *)directoryArray {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.fileLoadType = OSFileLoadTypeCurrentDirectory;
        [self commonInit];
        self.directoryArray = directoryArray;
    }
    return self;
}

- (void)commonInit {
    _fileManager = [OSFileManager defaultManager];
     _displayHiddenFiles = NO;
    _loadFileQueue = [NSOperationQueue new];
    __weak typeof(self) weakSelf = self;
    NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    _currentFolderHelper = [DirectoryWatcher watchFolderWithPath:self.rootDirectory directoryDidChange:^(DirectoryWatcher *folderWatcher) {
        [weakSelf reloadFiles];
    }];
    
    if (![self.rootDirectory isEqualToString:documentPath]) {
        _documentFolderHelper = [DirectoryWatcher watchFolderWithPath:documentPath directoryDidChange:^(DirectoryWatcher *folderWatcher) {
            [weakSelf reloadFiles];
        }];
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupViews];
    __weak typeof(self) weakSelf = self;
    switch (self.fileLoadType) {
        case OSFileLoadTypeCurrentDirectory: {
            [self loadFileWithDirectoryArray:self.directoryArray completion:^(NSArray *fileItems) {
                weakSelf.files = fileItems.copy;
                [weakSelf.collectionView reloadData];
            }];
            break;
        }
        case OSFileLoadTypeSubDirectory: {
            [self loadFileWithDirectoryPath:self.rootDirectory completion:^(NSArray *fileItems) {
                weakSelf.files = fileItems.copy;
                [weakSelf.collectionView reloadData];
            }];
            break;
        }
        default:
            break;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self check3DTouch];
}

- (void)setupViews {
    self.navigationItem.title = @"文件管理";
    if (self.rootDirectory.length) {
        self.navigationItem.title = [self.rootDirectory lastPathComponent];
        if ([self.rootDirectory isEqualToString:[OSFileConfigUtils getDocumentPath]]) {
            self.navigationItem.title = @"iTunes文件";
        }
        else if ([self.rootDirectory isEqualToString:[OSFileConfigUtils getDownloadLocalFolderPath]]) {
            self.navigationItem.title = @"下载";
        }
    }
    self.view.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    
    [self.view addSubview:self.collectionView];
    [self makeCollectionViewConstr];
    [self setupNodataView];
}

- (void)setupNodataView {
    __weak typeof(self) weakSelf = self;
    
    self.collectionView.noDataPlaceholderDelegate = self;
    if ([self isDownloadBrowser]) {
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

- (void)loadFileWithDirectoryArray:(NSArray<NSString *> *)directoryArray completion:(void (^)(NSArray *fileItems))completion {
    [_loadFileQueue cancelAllOperations];
    [_loadFileQueue addOperationWithBlock:^{
        NSMutableArray *array = @[].mutableCopy;
        [directoryArray enumerateObjectsUsingBlock:^(NSString * _Nonnull fullPath, NSUInteger idx, BOOL * _Nonnull stop) {
            OSFileAttributeItem *model = [[OSFileAttributeItem alloc] initWithPath:fullPath];
            if (model) {
                NSError *error = nil;
                NSArray *subFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPath error:&error];
                if (!error) {
                    if (!_displayHiddenFiles) {
                        subFiles = [self removeHiddenFilesFromFiles:subFiles];
                    }
                    model.subFileCount = subFiles.count;
                }
                
                [array addObject:model];
            }
        }];
        
        
        if (!_displayHiddenFiles) {
            array = [[self removeHiddenFilesFromFiles:array] mutableCopy];
        }
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(array);
            });
        }
        
    }];
  
   
}

- (void)loadFileWithDirectoryPath:(NSString *)directoryPath completion:(void (^)(NSArray *fileItems))completion {
    [_loadFileQueue cancelAllOperations];
    [_loadFileQueue addOperationWithBlock:^{
        
        NSError *error = nil;
        NSArray *tempFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:&error];
        if (error) {
            NSLog(@"Error: %@", error);
        }
        NSArray *files = [self sortedFiles:tempFiles];
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:files.count];
        [files enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *fullPath = [directoryPath stringByAppendingPathComponent:obj];
            OSFileAttributeItem *model = [[OSFileAttributeItem alloc] initWithPath:fullPath];
            if (model) {
                NSError *error = nil;
                NSArray *subFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPath error:&error];
                if (!error) {
                    if (!_displayHiddenFiles) {
                        subFiles = [self removeHiddenFilesFromFiles:subFiles];
                    }
                    model.subFileCount = subFiles.count;
                }
                
                [array addObject:model];
            }
           
        }];
        
        if (!_displayHiddenFiles) {
            array = [[self removeHiddenFilesFromFiles:array] mutableCopy];
        }
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(array);
            });
        }
    }];
}

- (void)setDisplayHiddenFiles:(BOOL)displayHiddenFiles {
    if (_displayHiddenFiles == displayHiddenFiles) {
        return;
    }
    _displayHiddenFiles = displayHiddenFiles;
    __weak typeof(self) weakSelf = self;
    switch (self.fileLoadType) {
        case OSFileLoadTypeCurrentDirectory: {
            [self loadFileWithDirectoryArray:self.directoryArray completion:^(NSArray *fileItems) {
                weakSelf.files = fileItems.copy;
                [weakSelf.collectionView reloadData];
            }];
            break;
        }
        case OSFileLoadTypeSubDirectory: {
            [self loadFileWithDirectoryPath:self.rootDirectory completion:^(NSArray *fileItems) {
                weakSelf.files = fileItems.copy;
                [weakSelf.collectionView reloadData];
            }];
            break;
        }
        default:
            break;
    }
    
}

- (NSArray *)removeHiddenFilesFromFiles:(NSArray *)files {
    @synchronized (self) {
        NSMutableArray *tempFiles = [files mutableCopy];
        NSIndexSet *indexSet = [tempFiles indexesOfObjectsPassingTest:^BOOL(OSFileAttributeItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[OSFileAttributeItem class]]) {
                return [obj.fullPath.lastPathComponent hasPrefix:@"."];
            } else if ([obj isKindOfClass:[NSString class]]) {
                NSString *path = (NSString *)obj;
                return [path.lastPathComponent hasPrefix:@"."];
            }
            return NO;
        }];
        [tempFiles removeObjectsAtIndexes:indexSet];
        return tempFiles;
    }
    
}


- (void)reloadFiles {
    __weak typeof(self) weakSelf = self;
    switch (self.fileLoadType) {
        case OSFileLoadTypeCurrentDirectory: {
            [self loadFileWithDirectoryArray:self.directoryArray completion:^(NSArray *fileItems) {
                weakSelf.files = fileItems.copy;
                [weakSelf.collectionView reloadData];
            }];
            break;
        }
        case OSFileLoadTypeSubDirectory: {
            [self loadFileWithDirectoryPath:self.rootDirectory completion:^(NSArray *fileItems) {
                weakSelf.files = fileItems.copy;
                [weakSelf.collectionView reloadData];
            }];
            break;
        }
        default:
            break;
    }
    
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
    // 需要将location在self.view上的坐标转换到tableView上，才能从tableView上获取到当前indexPath
    CGPoint targetLocation = [self.view convertPoint:location toView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:targetLocation];
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
#pragma mark -
////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.files.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    OSFileCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.fileModel = self.files[indexPath.row];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.indexPath = indexPath;
    UIViewController *vc = [self previewControllerByIndexPath:indexPath];
    [self jumpToDetailControllerToViewController:vc atIndexPath:indexPath];
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

- (void)jumpToDetailControllerToViewController:(UIViewController *)viewController atIndexPath:(NSIndexPath *)indexPath {
    NSString *newPath = self.files[indexPath.row].fullPath;
    BOOL isDirectory;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:newPath isDirectory:&isDirectory];
    NSURL *url = [NSURL fileURLWithPath:newPath];
    if (fileExists) {
        if (isDirectory) {
            OSFileCollectionViewController *vc = (OSFileCollectionViewController *)viewController;
            [self.navigationController showViewController:vc sender:self];
            
        } else if (![QLPreviewController canPreviewItem:url]) {
            FilePreviewViewController *preview = (FilePreviewViewController *)viewController;
            preview.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonClick)];
            UINavigationController *detailNavController = [[UINavigationController alloc] initWithRootViewController:preview];
            
            [self.navigationController showDetailViewController:detailNavController sender:self];
        } else {
            
            QLPreviewController *preview = (QLPreviewController *)viewController;
            preview.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonClick)];
            UINavigationController *detailNavController = [[UINavigationController alloc] initWithRootViewController:preview];
            [self.navigationController showDetailViewController:detailNavController sender:self];
        }
    }
}

- (void)backButtonClick {
    UINavigationController * navigationController = (UINavigationController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    if (self.presentedViewController || navigationController.topViewController.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}


- (UIViewController *)previewControllerByIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath || !self.files.count) {
        return nil;
    }
    NSString *newPath = self.files[indexPath.row].fullPath;
    NSURL *url = [NSURL fileURLWithPath:newPath];
    BOOL isDirectory;
    BOOL fileExists = [[NSFileManager defaultManager ] fileExistsAtPath:newPath isDirectory:&isDirectory];
    UIViewController *vc = nil;
    if (fileExists) {
        if (isDirectory) {
            vc = [[OSFileCollectionViewController alloc] initWithRootDirectory:newPath];
            
        } else if (![QLPreviewController canPreviewItem:url]) {
            vc = [[FilePreviewViewController alloc] initWithPath:newPath];
        } else {
            QLPreviewController *preview= [[QLPreviewController alloc] init];
            preview.dataSource = self;
            vc = preview;
        }
    }
    return vc;
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////
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
    NSString *newPath = self.files[self.indexPath.row].fullPath;
    
    return [NSURL fileURLWithPath:newPath];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Sorted files
////////////////////////////////////////////////////////////////////////
- (NSArray *)sortedFiles:(NSArray *)files {
    return [files sortedArrayWithOptions:NSSortConcurrent usingComparator:^NSComparisonResult(NSString* file1, NSString* file2) {
        NSString *newPath1 = [self.rootDirectory stringByAppendingPathComponent:file1];
        NSString *newPath2 = [self.rootDirectory stringByAppendingPathComponent:file2];
        
        BOOL isDirectory1, isDirectory2;
        [[NSFileManager defaultManager ] fileExistsAtPath:newPath1 isDirectory:&isDirectory1];
        [[NSFileManager defaultManager ] fileExistsAtPath:newPath2 isDirectory:&isDirectory2];
        
        if (isDirectory1 && !isDirectory2) {
            return NSOrderedAscending;
        }
        
        return  NSOrderedDescending;
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
        CGPoint point = [longPress locationInView:self.collectionView];
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
        
        if (self.longPressCallBack) {
            self.longPressCallBack(indexPath);
        }
        
        self.longPress.enabled = NO;
        UIViewController *vc = [self previewControllerByIndexPath:indexPath];
        [self jumpToDetailControllerToViewController:vc atIndexPath:indexPath];
    }
}



////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

- (void)makeCollectionViewConstr {
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_collectionView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_collectionView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_collectionView]|" options:0 metrics:nil views:views]];
}


- (OSFileCollectionViewFlowLayout *)flowLayout {
    
    if (_flowLayout == nil) {
        
        OSFileCollectionViewFlowLayout *layout = [OSFileCollectionViewFlowLayout new];
        _flowLayout = layout;
        layout.itemSpacing = 20.0;
        layout.lineSpacing = 20.0;
        layout.lineSize = 30.0;
        layout.lineItemCount = 3;
        layout.lineMultiplier = 1.15;
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.sectionsStartOnNewLine = NO;

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
        _collectionView = collectionView;
        _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        _collectionView.contentInset = UIEdgeInsetsMake(20, 20, 0, 20);
    }
    return _collectionView;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NoDataPlaceholderDelegate
////////////////////////////////////////////////////////////////////////

- (BOOL)noDataPlaceholderShouldAllowScroll:(UIScrollView *)scrollView {
    return YES;
}

- (void)noDataPlaceholder:(UIScrollView *)scrollView didTapOnContentView:(UITapGestureRecognizer *)tap {
    [self noDataPlaceholder:scrollView didTapOnContentView:tap];
}


- (CGFloat)contentOffsetYForNoDataPlaceholder:(UIScrollView *)scrollView {
    if ([UIDevice currentDevice].orientation == UIDeviceOrientationPortrait) {
        return 120.0;
    }
    return 80.0;
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

    return [UIImage imageNamed:@"file_noData"];
}


- (NSAttributedString *)noDataReloadButtonAttributedStringWithState:(UIControlState)state {
    return [self attributedStringWithText:@"查看下载页" color:[UIColor colorWithRed:49/255.0 green:194/255.0 blue:124/255.0 alpha:1.0] fontSize:15.0];
}

- (void)noDataPlaceholder:(UIScrollView *)scrollView didClickReloadButton:(UIButton *)button {
    self.tabBarController.selectedIndex = 1;
    self.navigationController.viewControllers = @[self.navigationController.viewControllers.firstObject];
}


- (NSAttributedString *)noDataTextLabelAttributedString {
    NSString *string = nil;
    if ([self isDownloadBrowser]) {
        string = @"没有下载完成文件\n去查看下载页是否有文件在下载中";
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
#pragma mark - Others
////////////////////////////////////////////////////////////////////////

- (BOOL)isDownloadBrowser {
    return [self.rootDirectory isEqualToString:[OSFileConfigUtils getDownloadLocalFolderPath]];
}


@end
