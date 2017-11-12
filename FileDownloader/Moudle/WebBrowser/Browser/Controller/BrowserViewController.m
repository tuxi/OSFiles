//
//  BrowserViewController.m
//  WebBrowser
//
//  Created by Null on 16/7/30.
//  Copyright © 2016年 Null. All rights reserved.
//

#import <StoreKit/StoreKit.h>

#import "BrowserViewController.h"
#import "BrowserContainerView.h"
#import "BrowserTopToolBar.h"
#import "BrowserHeader.h"
#import "BrowserBottomToolBar.h"
#import "CardMainView.h"
#import "SettingsViewController.h"
#import "SettingsTableViewController.h"
#import "HistoryTableViewController.h"
#import "DelegateManager+WebViewDelegate.h"
#import "BookmarkTableViewController.h"
#import "BookmarkDataManager.h"
#import "BookmarkItemEditViewController.h"
#import "FindInPageBar.h"
#import "KeyboardHelper.h"
#import "NSURL+ZWUtility.h"
#import "OSFileDownloaderManager.h"
#import "YCXMenu.h"
#import "NSObject+InterfaceOrientationExtensions.h"
#import "OSXMLDocumentItem.h"

static NSString *const kBrowserViewControllerAddBookmarkSuccess = @"添加书签成功";
static NSString *const kBrowserViewControllerAddBookmarkFailure = @"添加书签失败";

@interface BrowserViewController () <BrowserBottomToolBarButtonClickedDelegate,  UIViewControllerRestoration, KeyboardHelperDelegate>

@property (nonatomic, strong) BrowserContainerView *browserContainerView;
@property (nonatomic, strong) BrowserBottomToolBar *bottomToolBar;
@property (nonatomic, strong) BrowserTopToolBar *browserTopToolBar;
@property (nonatomic, assign) CGFloat lastContentOffset;
@property (nonatomic, assign) BOOL isWebViewDecelerate;
@property (nonatomic, assign) ScrollDirection webViewScrollDirection;
@property (nonatomic, weak) id<BrowserBottomToolBarButtonClickedDelegate> browserButtonDelegate;
@property (nonatomic, strong) FindInPageBar *findInPageBar;
@property (nonatomic, weak) NSLayoutConstraint *findInPageBarbottomLayoutConstaint;

@end

@implementation BrowserViewController

SYNTHESIZE_SINGLETON_FOR_CLASS(BrowserViewController)

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initializeView];
    
    [self initializeNotification];

    self.lastContentOffset = - TOP_TOOL_BAR_HEIGHT;
    
    [[DelegateManager sharedInstance] registerDelegate:self forKeys:@[DelegateManagerWebView, DelegateManagerFindInPageBarDelegate]];
    [[KeyboardHelper sharedInstance] addDelegate:self];
    
    self.restorationIdentifier = NSStringFromClass([self class]);
    self.restorationClass = [self class];
//    [self recoverToolBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self recoverToolBar];
    [self applyInterfaceOrientation:UIDeviceOrientationPortrait interfaceOrientationDidChangeBlock:^(InterfaceOrientation orientation) {
        [self recoverToolBar];
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)initializeView{
    self.view.backgroundColor = UIColorFromRGB(0xF8F8F8);
    
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:nil action:nil];
    [self.navigationItem setBackBarButtonItem:backItem];
    
    self.browserContainerView = ({
        BrowserContainerView *browserContainerView = [[BrowserContainerView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height)];
        [self.view addSubview:browserContainerView];
        browserContainerView.translatesAutoresizingMaskIntoConstraints = NO;
        
        if (@available(iOS 11.0, *)) {
            NSLayoutConstraint *top = [browserContainerView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:0.0];
            NSLayoutConstraint *left = [browserContainerView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:0.0];
            NSLayoutConstraint *right = [browserContainerView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:0.0];
            NSLayoutConstraint *bottom = [browserContainerView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:0];
            [NSLayoutConstraint activateConstraints:@[top, bottom, left, right]];
        } else {
            if (@available(iOS 9.0, *)) {
                NSLayoutConstraint *top = [browserContainerView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor];
                NSLayoutConstraint *bottom = [browserContainerView.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor constant:0];
                NSLayoutConstraint *left = [browserContainerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor];
                NSLayoutConstraint *right = [browserContainerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor];
                [NSLayoutConstraint activateConstraints:@[top, bottom, left, right]];
            } else {
                [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[browserContainerView]|" options:kNilOptions metrics:nil views:@{@"browserContainerView": browserContainerView}]];
                [self.view addConstraint:[NSLayoutConstraint constraintWithItem:browserContainerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
                [self.view addConstraint:[NSLayoutConstraint constraintWithItem:browserContainerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
            }
        }
        
        
        self.browserButtonDelegate = browserContainerView;

        browserContainerView;
    });
    
    self.browserTopToolBar = ({
        BrowserTopToolBar *browserTopToolBar = [[BrowserTopToolBar alloc] initWithFrame:CGRectMake(0, 0, self.view.width, TOP_TOOL_BAR_HEIGHT)];
        [self.view addSubview:browserTopToolBar];
        browserTopToolBar.translatesAutoresizingMaskIntoConstraints = NO;
        
        if (@available(iOS 11.0, *)) {
            NSLayoutConstraint *top = [browserTopToolBar.topAnchor     constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor];
             NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:browserTopToolBar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:TOP_TOOL_BAR_HEIGHT];
            NSLayoutConstraint *left = [browserTopToolBar.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor];
            NSLayoutConstraint *right = [browserTopToolBar.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor];
            [NSLayoutConstraint activateConstraints:@[top, height, left, right]];
        } else {
            if (@available(iOS 9.0, *)) {
                NSLayoutConstraint *top = [browserTopToolBar.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor];
                NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:browserTopToolBar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:TOP_TOOL_BAR_HEIGHT];
                NSLayoutConstraint *left = [browserTopToolBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor];
                NSLayoutConstraint *right = [browserTopToolBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor];
                [NSLayoutConstraint activateConstraints:@[top, height, left, right]];
            } else {
                [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[browserTopToolBar]|" options:kNilOptions metrics:nil views:@{@"browserTopToolBar": browserTopToolBar}]];
                [self.view addConstraint:[NSLayoutConstraint constraintWithItem:browserTopToolBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
                 NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:browserTopToolBar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:TOP_TOOL_BAR_HEIGHT];
                [self.view addConstraint:height];
            }
        }
        
        browserTopToolBar.backgroundColor = UIColorFromRGB(0xF8F8F8);
        
        browserTopToolBar;
    });
    
    self.bottomToolBar = ({
        BrowserBottomToolBar *toolBar = [[BrowserBottomToolBar alloc] initWithFrame:CGRectMake(0, self.view.height - BOTTOM_TOOL_BAR_HEIGHT, self.view.width, BOTTOM_TOOL_BAR_HEIGHT)];
        [self.view addSubview:toolBar];
        
        toolBar.translatesAutoresizingMaskIntoConstraints = NO;
        
        if (@available(iOS 11.0, *)) {
            NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:toolBar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:BOTTOM_TOOL_BAR_HEIGHT];
            NSLayoutConstraint *left = [toolBar.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor];
            NSLayoutConstraint *right = [toolBar.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor];
            NSLayoutConstraint *bottom = [toolBar.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:0.0];
            [NSLayoutConstraint activateConstraints:@[height, left, right, bottom]];
        } else {
            [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[toolBar]|" options:kNilOptions metrics:nil views:@{@"toolBar": toolBar}]];
            [self.view addConstraint:[NSLayoutConstraint constraintWithItem:toolBar attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
            NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:toolBar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:BOTTOM_TOOL_BAR_HEIGHT];
            [self.view addConstraint:height];
        }
        
        
        toolBar.browserButtonDelegate = self;
        
        [self.browserContainerView addObserver:toolBar forKeyPath:@"webView" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial context:NULL];
    
        toolBar;
    });
}

#pragma mark - Notification

- (void)initializeNotification{
    [Notifier addObserver:self selector:@selector(recoverToolBar) name:kExpandHomeToolBarNotification object:nil];
    [Notifier addObserver:self selector:@selector(recoverToolBar) name:kWebTabSwitch object:nil];
}

#pragma mark - UIScrollViewDelegate Method

//- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
//    //点击新链接或返回时，scrollView会调用该方法
//    if (!(!scrollView.decelerating && !scrollView.dragging && !scrollView.tracking)) {
//        CGFloat yOffset = scrollView.contentOffset.y - self.lastContentOffset;
//
//        if (self.lastContentOffset > scrollView.contentOffset.y) {
//            if (_isWebViewDecelerate || (scrollView.contentOffset.y >= -TOP_TOOL_BAR_HEIGHT && scrollView.contentOffset.y <= 0)) {
//                //浮点数不能做精确匹配，不过此处用等于满足我的需求
//                if (!(self.browserTopToolBar.height == TOP_TOOL_BAR_HEIGHT)) {
//                    [self recoverToolBar];
//                }
//            }
//            self.webViewScrollDirection = ScrollDirectionDown;
//        }
//        else if (self.lastContentOffset < scrollView.contentOffset.y && scrollView.contentOffset.y >= - TOP_TOOL_BAR_HEIGHT)
//        {
//            if (!(scrollView.contentOffset.y < 0 && scrollView.decelerating)) {
//                [self handleToolBarWithOffset:yOffset];
//            }
//            self.webViewScrollDirection = ScrollDirectionUp;
//        }
//    }
//
//    self.lastContentOffset = scrollView.contentOffset.y;
//
//}

- (void)recoverToolBar{
//    [UIView animateWithDuration:.2 animations:^{
//        self.browserTopToolBar.height = TOP_TOOL_BAR_HEIGHT;
//        CGRect bottomRect = self.bottomToolBar.frame;
//        bottomRect.origin.y = self.view.height - BOTTOM_TOOL_BAR_HEIGHT;
//        self.bottomToolBar.frame = bottomRect;
//        self.browserContainerView.scrollView.contentInset = UIEdgeInsetsMake(TOP_TOOL_BAR_HEIGHT, 0, BOTTOM_TOOL_BAR_HEIGHT, 0);
//    }];
    self.browserContainerView.scrollView.contentInset = UIEdgeInsetsMake(TOP_TOOL_BAR_HEIGHT, 0, BOTTOM_TOOL_BAR_HEIGHT, 0);
}

- (void)hideTabBar {
    if (self.tabBarController.tabBar.hidden == YES) {
        return;
    }
    UIView *contentView;
    if ( [[self.tabBarController.view.subviews objectAtIndex:0] isKindOfClass:[UITabBar class]] )
        contentView = [self.tabBarController.view.subviews objectAtIndex:1];
    else
        contentView = [self.tabBarController.view.subviews objectAtIndex:0];
    contentView.frame = CGRectMake(contentView.bounds.origin.x,  contentView.bounds.origin.y,  contentView.bounds.size.width, contentView.bounds.size.height + self.tabBarController.tabBar.frame.size.height);
    self.tabBarController.tabBar.hidden = YES;
    
}

- (void)showTabBar {
    if (self.tabBarController.tabBar.hidden == NO) {
        return;
    }
    UIView *contentView;
    if ([[self.tabBarController.view.subviews objectAtIndex:0] isKindOfClass:[UITabBar class]])
        
        contentView = [self.tabBarController.view.subviews objectAtIndex:1];
    
    else
        
        contentView = [self.tabBarController.view.subviews objectAtIndex:0];
    contentView.frame = CGRectMake(contentView.bounds.origin.x, contentView.bounds.origin.y,  contentView.bounds.size.width, contentView.bounds.size.height - self.tabBarController.tabBar.frame.size.height);
    self.tabBarController.tabBar.hidden = NO;
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (self.webViewScrollDirection == ScrollDirectionDown) {
        self.isWebViewDecelerate = decelerate;
    }
    else
        self.isWebViewDecelerate = NO;
}

#pragma mark - Handle TopToolBar Scroll

- (void)handleToolBarWithOffset:(CGFloat)offset{
    CGRect bottomRect = self.bottomToolBar.frame;
    //缩小toolbar
    if (offset > 0) {
        if (self.browserTopToolBar.height - offset <= TOP_TOOL_BAR_THRESHOLD) {
            self.browserTopToolBar.height = TOP_TOOL_BAR_THRESHOLD;
            self.browserContainerView.scrollView.contentInset = UIEdgeInsetsMake(TOP_TOOL_BAR_THRESHOLD, 0, 0, 0);

            bottomRect.origin.y = self.view.height;
        }
        else
        {
            self.browserTopToolBar.height -= offset;
            CGFloat bottomRectYoffset = BOTTOM_TOOL_BAR_HEIGHT * offset / (TOP_TOOL_BAR_HEIGHT - TOP_TOOL_BAR_THRESHOLD);
            bottomRect.origin.y += bottomRectYoffset;
            UIEdgeInsets insets = self.browserContainerView.scrollView.contentInset;
            insets.top -= offset;
            insets.bottom -= bottomRectYoffset;
            self.browserContainerView.scrollView.contentInset = insets;
        }
    }
    else{
        if (self.browserTopToolBar.height + (-offset) >= TOP_TOOL_BAR_HEIGHT) {
            self.browserTopToolBar.height = TOP_TOOL_BAR_HEIGHT;
            bottomRect.origin.y = self.view.height - BOTTOM_TOOL_BAR_HEIGHT;
            self.browserContainerView.scrollView.contentInset = UIEdgeInsetsMake(TOP_TOOL_BAR_HEIGHT, 0, BOTTOM_TOOL_BAR_HEIGHT, 0);
        }
        else
        {
            self.browserTopToolBar.height += (-offset);
            CGFloat bottomRectYoffset = BOTTOM_TOOL_BAR_HEIGHT * (-offset) / (TOP_TOOL_BAR_HEIGHT - TOP_TOOL_BAR_THRESHOLD);
            bottomRect.origin.y -= bottomRectYoffset;
            UIEdgeInsets insets = self.browserContainerView.scrollView.contentInset;
            insets.top += (-offset);
            insets.bottom += bottomRectYoffset;
            self.browserContainerView.scrollView.contentInset = insets;
        }
    }
    
    self.bottomToolBar.frame = bottomRect;
//    [self hideTabBar];
}

#pragma mark - BrowserBottomToolBarButtonClickedDelegate

- (void)browserBottomToolBarButtonClickedWithTag:(BottomToolBarButtonTag)tag{
    if ([self.browserButtonDelegate respondsToSelector:@selector(browserBottomToolBarButtonClickedWithTag:)]) {
        [self.browserButtonDelegate browserBottomToolBarButtonClickedWithTag:tag];
    }
    if (tag == BottomToolBarMoreButtonTag) {
        // weak self_ must not nil
        WEAK_REF(self)
        [YCXMenu setSelectedColor:[UIColor redColor]];
        [YCXMenu setHasShadow:NO];
        [YCXMenu setArrowSize:6];
        [YCXMenu setCornerRadius:2];
        [YCXMenu setBackgrounColorEffect:YCXMenuBackgrounColorEffectSolid];
        [YCXMenu setTintColor:[UIColor colorWithRed:0.212 green:0.255 blue:0.678 alpha:1]];
        if ([YCXMenu isShow]){
            [YCXMenu dismissMenu];
        } else {
            NSArray *menuItemArray = [@[
                                        [YCXMenuItem menuItem:@"加入书签"
                                                        image:nil
                                                       target:self
                                                       action:@selector(addBookmark)],
                                        [YCXMenuItem menuItem:@"书签"
                                                        image:nil
                                                       target:self
                                                       action:@selector(pushBookmarkController)],
                                        [YCXMenuItem menuItem:@"历史"
                                                        image:nil
                                                       target:self
                                                       action:@selector(pushHistoryController)],
                                        [YCXMenuItem menuItem:@"设置"
                                                        image:nil
                                                       target:self
                                                       action:@selector(pushSettingController)],
                                        [YCXMenuItem menuItem:@"拷贝连接"
                                                        image:nil
                                                       target:self
                                                       action:@selector(handleCopyURLButtonClicked)],
                                        [YCXMenuItem menuItem:@"缓存"
                                                        image:nil
                                                       target:self
                                                       action:@selector(cacheHTMLResourcesWithMenuItem:)],
                                        ] mutableCopy];

            CGRect fromRect = self.bottomToolBar.frame;
            CGFloat widthOfOne = self.bottomToolBar.frame.size.width / 4;
            fromRect.origin.x = widthOfOne * 3;
            [YCXMenu showMenuInView:self.view fromRect:fromRect menuItems:menuItemArray selected:^(NSInteger index, YCXMenuItem *item) {
                NSLog(@"%@",item);
            }];
        }
        
    }
    if (tag == BottomToolBarMultiWindowButtonTag) {
        CardMainView *cardMainView = [[CardMainView alloc] initWithFrame:self.view.bounds];
        [cardMainView reloadCardMainViewWithCompletionBlock:^{
            UIImage *image = [self.view snapshot];
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            imageView.frame = cardMainView.bounds;
            [cardMainView addSubview:imageView];
            [self.view addSubview:cardMainView];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [imageView removeFromSuperview];
                [cardMainView changeCollectionViewLayout];
            });
        }];
    }
}



/// 缓存网页中的资源文件
- (void)cacheHTMLResourcesWithMenuItem:(YCXMenuItem *)menuItem {
    
    [YCXMenu setSelectedColor:[UIColor redColor]];
    [YCXMenu setHasShadow:NO];
    [YCXMenu setArrowSize:6];
    [YCXMenu setCornerRadius:2];
    [YCXMenu setBackgrounColorEffect:YCXMenuBackgrounColorEffectSolid];
    [YCXMenu setTintColor:[UIColor colorWithRed:0.212 green:0.255 blue:0.678 alpha:1]];
    if ([YCXMenu isShow]){
        [YCXMenu dismissMenu];
    } else {
        NSArray *menuItemArray = [@[
                                    [YCXMenuItem menuItem:@"视频"
                                                    image:nil
                                                   target:self
                                                   action:@selector(cacheVideos)],
                                    [YCXMenuItem menuItem:@"图片"
                                                    image:nil
                                                   target:self
                                                   action:@selector(cacheImages)],
                                    ] mutableCopy];
        
        CGRect fromRect = self.bottomToolBar.frame;
        CGFloat widthOfOne = self.bottomToolBar.frame.size.width / 4;
        fromRect.origin.x = widthOfOne * 3;
        [YCXMenu showMenuInView:self.view fromRect:fromRect menuItems:menuItemArray selected:^(NSInteger index, YCXMenuItem *item) {
            NSLog(@"%@",item);
        }];
    }
}

- (NSString *)getCurrentPageHTMLString {
    NSString *lJs = @"document.documentElement.innerHTML";
    NSString *lHtml = [self.browserContainerView.webView stringByEvaluatingJavaScriptFromString:lJs];
    return lHtml;
}

/// 缓存视频
- (void)cacheVideos {
    [OSXMLDocumentItem parseElementWithHTMLString:[self getCurrentPageHTMLString] parseCompletion:^(NSArray *videoURLs, NSArray *imageURLs) {
        NSString *string = [videoURLs componentsJoinedByString:@",\n"];
        NSArray *otherButtonTitles = @[@"全部缓存"];
        if (!videoURLs.count) {
            string = nil;
            otherButtonTitles = nil;
        }
        [UIAlertView showWithTitle:[NSString stringWithFormat:@"%ld个视频", videoURLs.count] message:string cancelButtonTitle:@"取消" otherButtonTitles:otherButtonTitles tapBlock:^(UIAlertView * _Nonnull alertView, NSInteger buttonIndex) {
            if (buttonIndex == 1) {
                [videoURLs enumerateObjectsUsingBlock:^(NSString *  _Nonnull url, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (!url.length) {
                        return;
                    }
                    [[OSFileDownloaderManager sharedInstance] start:url];
                }];
            }
        }];
    }];
}

/// 缓存图片
- (void)cacheImages {
    [OSXMLDocumentItem parseElementWithHTMLString:[self getCurrentPageHTMLString] parseCompletion:^(NSArray *videoURLs, NSArray *imageURLs) {
        NSString *string = [imageURLs componentsJoinedByString:@",\n"];
        if (!imageURLs.count) {
            string = nil;
        }
        [UIAlertView showWithTitle:[NSString stringWithFormat:@"%ld个图片", imageURLs.count] message:string cancelButtonTitle:@"取消" otherButtonTitles:@[@"全部缓存"] tapBlock:^(UIAlertView * _Nonnull alertView, NSInteger buttonIndex) {
            if (buttonIndex == 1) {
                [imageURLs enumerateObjectsUsingBlock:^(NSString *  _Nonnull url, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (!url.length) {
                        return;
                    }
                    [[OSFileDownloaderManager sharedInstance] start:url];
                }];
            }
        }];
    }];
}

/// 查看设置页
- (void)pushSettingController {
    [self pushTableViewControllerWithControllerName:[SettingsTableViewController class]];
}

/// 查看历史
- (void)pushHistoryController {
    [self pushTableViewControllerWithControllerName:[HistoryTableViewController class]];
}

/// 查看书签
- (void)pushBookmarkController {
    [self pushTableViewControllerWithControllerName:[BookmarkTableViewController class]];
}

- (void)pushTableViewControllerWithControllerName:(Class)class{
    if (![class isSubclassOfClass:[UITableViewController class]]) {
        return;
    }
    UITableViewController *vc = [[class alloc] initWithStyle:UITableViewStylePlain];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)handleCopyURLButtonClicked{
    NSURL *url = [NSURL URLWithString:self.browserContainerView.webView.mainFURL];
    BOOL success = NO;
    
    if (url) {
        if ([url isErrorPageURL]) {
            url = [url originalURLFromErrorURL];
        }
        UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
        pasteBoard.URL = url;
        success = YES;
    }

    [self.view showHUDWithMessage:success ? @"拷贝成功" : @"拷贝失败"];
}

- (void)addBookmark{
    BrowserWebView *webView = self.browserContainerView.webView;
    NSString *title = webView.mainFTitle;
    NSString *url = webView.mainFURL;
    
    if (title.length == 0 || url.length == 0) {
        [self.view showHUDWithMessage:kBrowserViewControllerAddBookmarkFailure];
        return;
    }
    
    BookmarkDataManager *dataManager = [[BookmarkDataManager alloc] init];
    
    BookmarkItemEditViewController *editVC = [[BookmarkItemEditViewController alloc] initWithDataManager:dataManager item:[BookmarkItemModel bookmarkItemWithTitle:title url:url] sectionIndex:[NSIndexPath indexPathForRow:0 inSection:0] operationKind:BookmarkItemOperationKindItemAdd completion:nil];
    
    UINavigationController *navigationVC = [[UINavigationController alloc] initWithRootViewController:editVC];
    
    [self presentViewController:navigationVC animated:YES completion:nil];
}

#pragma mark - Preseving and Restoring State

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder{
    BrowserViewController *controller = BrowserVC;
    return controller;
}

#pragma mark - FindInPageBarDelegate

- (void)findInPage:(FindInPageBar *)findInPage didFindPreviousWithText:(NSString *)text{
    [self.findInPageBar endEditing:YES];
}

- (void)findInPage:(FindInPageBar *)findInPage didFindNextWithText:(NSString *)text{
    [self.findInPageBar endEditing:YES];
}

- (void)findInPageDidPressClose:(FindInPageBar *)findInPage{
    [self updateFindInPageVisibility:NO];
}

- (void)updateFindInPageVisibility:(BOOL)visible{
    if (visible) {
        if (!self.findInPageBar) {
            FindInPageBar *findInPageBar = [FindInPageBar new];
            findInPageBar.translatesAutoresizingMaskIntoConstraints = NO;
            [self.view addSubview:findInPageBar];
            
            [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[findInPageBar]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(findInPageBar)]];
            [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[findInPageBar(44)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(findInPageBar)]];
            NSLayoutConstraint *bottomConstaint = [NSLayoutConstraint constraintWithItem:findInPageBar attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_bottomToolBar attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.f];
            [self.view addConstraint:bottomConstaint];
            self.findInPageBarbottomLayoutConstaint = bottomConstaint;
            
            self.findInPageBar = findInPageBar;
        }
    }
    else if (self.findInPageBar){
        [self.findInPageBar endEditing:YES];
        [self.findInPageBar removeFromSuperview];
        self.findInPageBar = nil;
    }
}

#pragma mark - FindInPageUpdateDelegate

- (void)findInPageDidUpdateCurrentResult:(NSInteger)currentResult{
    self.findInPageBar.currentResult = currentResult;
}

- (void)findInPageDidUpdateTotalResults:(NSInteger)totalResults{
    self.findInPageBar.totalResults = totalResults;
}

- (void)findInPageDidSelectForSelection:(NSString *)selection{
    [self updateFindInPageVisibility:YES];
    self.findInPageBar.text = selection;
}

#pragma mark - KeyboardHelperDelegate

- (void)keyboardHelper:(KeyboardHelper *)keyboardHelper keyboardWillShowWithState:(KeyboardState *)state{
    [self changeSearchInputViewPoint:state isShow:YES];
}

- (void)keyboardHelper:(KeyboardHelper *)keyboardHelper keyboardWillHideWithState:(KeyboardState *)state{
    [self changeSearchInputViewPoint:state isShow:NO];
}

- (void)changeSearchInputViewPoint:(KeyboardState *)state isShow:(BOOL)isShow{
    if (!(self.navigationController.topViewController == self && !self.presentedViewController && self.findInPageBar)) {
        return;
    }
    
    CGFloat keyBoardEndY = self.view.height - [state intersectionHeightForView:self.view];
    
    // 添加移动动画，使视图跟随键盘移动
    [UIView animateWithDuration:state.animationDuration animations:^{
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationCurve:state.animationCurve];
        [self.findInPageBarbottomLayoutConstaint setActive:NO];
        if (isShow) {
            NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.findInPageBar attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0f constant:keyBoardEndY];
            self.findInPageBarbottomLayoutConstaint = bottomConstraint;
            [self.view addConstraint:bottomConstraint];
        }
        else{
            NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.findInPageBar attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomToolBar attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.f];
            self.findInPageBarbottomLayoutConstaint = bottomConstraint;
            [self.view addConstraint:bottomConstraint];
        }
    }];
}


#pragma mark - Dealloc Method

- (void)dealloc{
    [Notifier removeObserver:self];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - 屏幕方向
////////////////////////////////////////////////////////////////////////
- (BOOL)shouldAutorotate {
    return YES;
}

// 支持的方向 只需要支持竖屏
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}
@end
