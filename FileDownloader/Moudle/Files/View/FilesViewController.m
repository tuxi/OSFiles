//
//  FilesViewController.m
//  OSFileDownloader
//
//  Created by Ossey on 2017/6/10.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "FilesViewController.h"
#import "AppDelegate.h"
#import "OSFileDownloadCell.h"
#import "FilesTableViewModel.h"
#import "OSFileDownloaderManager.h"
#import "OSFileDownloadConst.h"

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
    
    self.navigationItem.title = @"文件管理";
    self.tableViewModel = [FilesTableViewModel new];
    [self.tableViewModel prepareTableView:self.tableView];
    [self addObservers];
    __weak typeof(self) weakSelf = self;
    
    
    [self.tableViewModel getDataSourceBlock:^id{
         return [[OSFileDownloaderManager sharedInstance] downloadedItems];
    } completion:^{
        [weakSelf.tableView reloadData];
    }];
#if DEBUG
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"clear"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                     action:@selector(resertDownlod)];
#endif
}


/// 重新下载全部
- (void)resertDownlod {
    [[OSFileDownloaderManager sharedInstance] clearAllDownloadTask];
    __weak typeof(self) weakSelf = self;
    [self.tableViewModel getDataSourceBlock:^id{
        
        return [[OSFileDownloaderManager sharedInstance] downloadedItems];
    } completion:^{
        [weakSelf.tableView reloadData];
    }];
    [self.tabBarController performSelector:@selector(setSelectedIndex:)
                                withObject:@1
                                afterDelay:0.5];

    [[NSNotificationCenter defaultCenter] postNotificationName:OSFileDownloaderResetDownloadsNotification
                                                        object:nil];
}


- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadSuccess:)
                                                 name:OSFileDownloadSussessNotification
                                               object:nil];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Notify
////////////////////////////////////////////////////////////////////////

- (void)downloadSuccess:(NSNotification *)noti {
    __weak typeof(self) weakSelf = self;
    [self.tableViewModel getDataSourceBlock:^id{
        
        return [[OSFileDownloaderManager sharedInstance] downloadedItems];
    } completion:^{
        [weakSelf.tableView reloadData];
    }];
}


////////////////////////////////////////////////////////////////////////
#pragma mark - NoDataPlaceholderExtend
////////////////////////////////////////////////////////////////////////


- (NSAttributedString *)noDataReloadButtonAttributedStringWithState:(UIControlState)state {
    return [self attributedStringWithText:@"查看下载页" color:[UIColor colorWithRed:49/255.0 green:194/255.0 blue:124/255.0 alpha:1.0] fontSize:15.0];
}

- (void)noDataPlaceholder:(UIScrollView *)scrollView didClickReloadButton:(UIButton *)button {
    self.tabBarController.selectedIndex = 1;
}

//- (NSAttributedString *)noDataDetailLabelAttributedString {
//    return [self attributedStringWithText:@"无文件" color:[UIColor grayColor] fontSize:16];
//}

- (NSAttributedString *)noDataTextLabelAttributedString {
    return [self attributedStringWithText:@"没有下载完成文件\n去查看下载页是否有文件在下载中" color:[UIColor grayColor] fontSize:16];;
}

@end
