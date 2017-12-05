//
//  OSFileSearchResultsController.m
//  FileBrowser
//
//  Created by Swae on 2017/11/20.
//  Copyright © 2017年 xiaoyuan. All rights reserved.
//

#import "OSFileSearchResultsController.h"
#import "OSFileAttributeItem.h"
#import "NSString+OSContainsEeachCharacter.h"
#import "OSFileCollectionViewFlowLayout.h"
#import "OSFileCollectionViewCell.h"
#import "OSFilePreviewViewController.h"
#import "OSFileCollectionViewController.h"
#import "MBProgressHUD+BBHUD.h"
#import "OSFileBrowserAppearanceConfigs.h"
#import "UIViewController+XYExtensions.h"

static NSString * const kSearchCellIdentifier = @"OSFileSearchResultsController";

@interface OSFileSearchResultsController () <UICollectionViewDelegate, UICollectionViewDataSource, QLPreviewControllerDataSource, QLPreviewControllerDelegate>


@end

@implementation OSFileSearchResultsController

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    if (!layout) {
        layout = [self createDefaultFlowLayout];
    }
    if (self = [super initWithCollectionViewLayout:layout]) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupViews];
    [self commonInit];
}

- (void)commonInit {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotateToInterfaceOrientation) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)setupViews {
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
    [self.collectionView registerClass:[OSFileCollectionViewCell class] forCellWithReuseIdentifier:kSearchCellIdentifier];
    self.collectionView.keyboardDismissMode = YES;
    [self updateCollectionViewFlowLayout:(OSFileCollectionViewFlowLayout *)self.collectionView.collectionViewLayout];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}


////////////////////////////////////////////////////////////////////////
#pragma mark - UISearchResultsUpdating
////////////////////////////////////////////////////////////////////////

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [self updateViewFrame];
    
    // 获取搜索框中用户输入的字符串
    NSString *searchString = [searchController.searchBar text];
    // 指定过滤条件，SELF表示要查询集合中对象，contain[c]表示包含字符串，%@是字符串内容
    // NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[c] %@", searchString];
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        if ([evaluatedObject isKindOfClass:[NSString class]]) {
            return [(NSString *)evaluatedObject containsEachCharacter:searchString];
        } else if ([evaluatedObject isKindOfClass:[NSDictionary class]]) {
            return [((OSFileAttributeItem*)evaluatedObject).displayName containsEachCharacter:searchString];
        } else if ([evaluatedObject isKindOfClass:[OSFileAttributeItem class]]) {
            return [((OSFileAttributeItem*)evaluatedObject).displayName containsEachCharacter:searchString];
        }
        return [evaluatedObject containsObject:searchString];
    }];
    //如果搜索数组中存在对象，即上次搜索的结果，则清除这些对象
    if (self.arrayOfSeachResults != nil) {
        [self.arrayOfSeachResults removeAllObjects];
    }
    // 通过过滤条件过滤数据
    NSMutableArray<OSFileAttributeItem *> *result = [[self.files filteredArrayUsingPredicate:predicate] mutableCopy];
    self.arrayOfSeachResults = result;
    [self.collectionView reloadData];
}

#pragma mark *** UICollectionViewDataSource ***

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.arrayOfSeachResults.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    OSFileCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kSearchCellIdentifier forIndexPath:indexPath];
    
    // 显示搜索结果
    OSFileAttributeItem *searchResult = self.arrayOfSeachResults[indexPath.row];
    // 原始搜索结果字符串.
    NSString *originResult = searchResult.displayName;
    
    /*
     // 获取关键字的位置
     NSRange range = [originResult rangeOfString:self.searchController.searchBar.text];
     // 转换成可以操作的字符串类型.
     NSMutableAttributedString *attribute = [[NSMutableAttributedString alloc] initWithString:originResult];
     
     // 添加属性(粗体)
     [attribute addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:20] range:range];
     // 关键字高亮
     [attribute addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:range];
     */
    
    // 转换成可以操作的字符串类型.
    NSMutableAttributedString *attribute = [[NSMutableAttributedString alloc] initWithString:originResult];
    for (NSValue *rangeValue in [originResult rangeArrayOfEachCharacter:self.searchController.searchBar.text]) {
        // 获取关键字的位置
        NSRange range;
        [rangeValue getValue:&range];
        
        // 添加属性(粗体)
        [attribute addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16] range:range];
        // 关键字高亮
        [attribute addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:range];
    }
    
    cell.fileModel.displayNameAttributedText = attribute;
    
    cell.fileModel = searchResult;
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UIViewController *vc = [self previewControllerByIndexPath:indexPath];
    [self showDetailController:vc atIndexPath:indexPath];
    if ([vc isKindOfClass:[OSPreviewViewController class]]) {
        OSPreviewViewController *pvc = (OSPreviewViewController *)vc;
        pvc.currentPreviewItemIndex = indexPath.item;
    }
}


#pragma mark *** QLPreviewControllerDataSource ***

- (BOOL)previewController:(QLPreviewController *)controller shouldOpenURL:(NSURL *)url forPreviewItem:(id <QLPreviewItem>)item {
    
    return YES;
}

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return self.arrayOfSeachResults.count;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger) index {
    NSString *newPath = self.arrayOfSeachResults[index].path;
    
    return [NSURL fileURLWithPath:newPath];
}

#pragma mark *** QLPreviewControllerDelegate ***

- (CGRect)previewController:(QLPreviewController *)controller frameForPreviewItem:(id <QLPreviewItem>)item inSourceView:(UIView * _Nullable * __nonnull)view {
    return self.view.frame;
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////
- (UIViewController *)previewControllerByIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath || !self.arrayOfSeachResults.count) {
        return nil;
    }
    OSFileAttributeItem *newItem = self.arrayOfSeachResults[indexPath.row];
    return [self previewControllerWithFileItem:newItem];
}

- (UIViewController *)previewControllerWithFileItem:(OSFileAttributeItem *)newItem {
    if (newItem) {
        BOOL isDirectory;
        BOOL fileExists = [[NSFileManager defaultManager ] fileExistsAtPath:newItem.path isDirectory:&isDirectory];
        UIViewController *vc = nil;
        if (fileExists) {
            if (newItem.isDirectory) {
                vc = [[OSFileCollectionViewController alloc] initWithDirectory:newItem.path controllerMode:OSFileCollectionViewControllerModeDefault];
                
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

- (void)showDetailController:(UIViewController *)viewController parentPath:(NSString *)parentPath {
    if (!viewController) {
        return;
    }
    viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonClick)];
    UINavigationController *nac = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self showDetailViewController:nac sender:self];
    
}

- (void)showDetailController:(UIViewController *)viewController atIndexPath:(NSIndexPath *)indexPath {
    NSString *newPath = self.arrayOfSeachResults[indexPath.row].path;
    if (!newPath.length) {
        return;
    }
    [self showDetailController:viewController parentPath:newPath];
}

- (void)backButtonClick {
    [[UIViewController xy_topViewController] dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (OSFileCollectionViewFlowLayout *)createDefaultFlowLayout {
    
    OSFileCollectionViewFlowLayout *layout = [OSFileCollectionViewFlowLayout new];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.sectionsStartOnNewLine = NO;
    return layout;
}


////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////
- (void)updateCollectionViewFlowLayout:(OSFileCollectionViewFlowLayout *)flowLayout {
    if ([OSFileCollectionViewFlowLayout collectionLayoutStyle] == YES) {
        flowLayout.itemSpacing = 10.0;
        flowLayout.lineSpacing = 10.0;
        flowLayout.lineItemCount = 1;
        flowLayout.lineMultiplier = 0.12;
        UIEdgeInsets contentInset = self.collectionView.contentInset;
        contentInset.left = 0.0;
        contentInset.right = 0.0;
        self.collectionView.contentInset = contentInset;
    }
    else {
        flowLayout.itemSpacing = 20.0;
        flowLayout.lineSpacing = 20.0;
        UIEdgeInsets contentInset = self.collectionView.contentInset;
        contentInset.left = 20.0;
        contentInset.right = 20.0;
        self.collectionView.contentInset = contentInset;
        flowLayout.lineMultiplier = 1.19;
        
        
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        if (UIInterfaceOrientationIsPortrait(orientation)) {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                flowLayout.lineItemCount = 6;
            }
            else {
                flowLayout.lineItemCount = 3;
            }
            
        }
        else {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                flowLayout.lineItemCount = 10;
            }
            else {
                flowLayout.lineItemCount = 5;
            }
        }
    }
}


////////////////////////////////////////////////////////////////////////
#pragma mark - Notification
////////////////////////////////////////////////////////////////////////
- (void)rotateToInterfaceOrientation {
    [self updateViewFrame];
    [self updateCollectionViewFlowLayout:(OSFileCollectionViewFlowLayout *)self.collectionView.collectionViewLayout];
    /// 屏幕旋转时重新布局item
    [self.collectionView.collectionViewLayout invalidateLayout];
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

- (void)updateViewFrame {
    CGFloat topMargin = self.searchController.searchBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;
    CGRect viewFrame = self.view.frame;
    viewFrame.origin.y = topMargin;
    viewFrame.size.height = [UIScreen mainScreen].bounds.size.height - topMargin;
    self.view.frame = viewFrame;
}

@end

