//
//  FilesViewController.m
//  FileDownloader
//
//  Created by Ossey on 2017/6/10.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "FilesViewController.h"
#import "AppDelegate.h"
#import "FileDownloadCell.h"
#import "FilesTableViewModel.h"
#import "FileDownloaderManager.h"
#import "FileDownloadConst.h"

@interface FilesViewController ()

@end

@implementation FilesViewController

////////////////////////////////////////////////////////////////////////
#pragma mark - Life cycle
////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setup {
    
    self.navigationItem.title = @"Files";
    self.tableViewModel = [FilesTableViewModel new];
    [self.tableViewModel prepareTableView:self.tableView];
    [self addObservers];
    __weak typeof(self) weakSelf = self;
    self.tableView.reloadButtonClickBlock = ^{
        weakSelf.tabBarController.selectedIndex = 1;
    };
    
    
    [self.tableViewModel getDataSourceBlock:^id{
         return [[FileDownloaderManager sharedInstance] downloadedItems];
    } completion:^{
        [weakSelf.tableView reloadData];
    }];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"clear"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(resertDownlod)];
}

/// 重新下载全部
- (void)resertDownlod {
    [[FileDownloaderManager sharedInstance] clearAllDownloadTask];
    __weak typeof(self) weakSelf = self;
    [self.tableViewModel getDataSourceBlock:^id{
        
        return [[FileDownloaderManager sharedInstance] downloadedItems];
    } completion:^{
        [weakSelf.tableView reloadData];
    }];
    [self.tabBarController performSelector:@selector(setSelectedIndex:)
                                withObject:@1
                                afterDelay:0.5];

    [[NSNotificationCenter defaultCenter] postNotificationName:FileDownloaderResetDownloadsNotification
                                                        object:nil];
}


- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadSuccess:)
                                                 name:FileDownloadSussessNotification
                                               object:nil];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Notify
////////////////////////////////////////////////////////////////////////

- (void)downloadSuccess:(NSNotification *)noti {
    __weak typeof(self) weakSelf = self;
    [self.tableViewModel getDataSourceBlock:^id{
        
        return [[FileDownloaderManager sharedInstance] downloadedItems];
    } completion:^{
        [weakSelf.tableView reloadData];
    }];
}


////////////////////////////////////////////////////////////////////////
#pragma mark - Config NoDataPlaceholderExtend
////////////////////////////////////////////////////////////////////////

- (NSAttributedString *)titleAttributedStringForNoDataPlaceholder {
    
    NSString *text = @"本地无下载文件\n去查看下载页是否有文件在下载中";
    
    UIFont *font = nil;
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_4) {
        font = [UIFont monospacedDigitSystemFontOfSize:18.0 weight:UIFontWeightRegular];
    } else {
        font = [UIFont boldSystemFontOfSize:18.0];
    }
    UIColor *textColor = [UIColor grayColor];
    
    NSMutableDictionary *attributeDict = [NSMutableDictionary dictionaryWithCapacity:0];
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.lineBreakMode = NSLineBreakByWordWrapping;
    style.alignment = NSTextAlignmentCenter;
    
    [attributeDict setObject:font forKey:NSFontAttributeName];
    [attributeDict setObject:textColor forKey:NSForegroundColorAttributeName];
    [attributeDict setObject:style forKey:NSParagraphStyleAttributeName];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:attributeDict];
    
    return attributedString;
    
}

- (NSAttributedString *)reloadbuttonTitleAttributedStringForNoDataPlaceholder {
    
    UIFont *font = nil;
    
    NSString *text = @"查看下载页";
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_4) {
        font = [UIFont monospacedDigitSystemFontOfSize:15.0 weight:UIFontWeightRegular];
    } else {
        font = [UIFont boldSystemFontOfSize:15.0];
    }
    UIColor *textColor = [UIColor whiteColor];
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    if (font) [attributes setObject:font forKey:NSFontAttributeName];
    if (textColor) [attributes setObject:textColor forKey:NSForegroundColorAttributeName];
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}


@end
