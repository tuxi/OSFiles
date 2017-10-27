//
//  DownloadsViewController.m
//  OSFileDownloader
//
//  Created by Ossey on 2017/6/10.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "DownloadsViewController.h"
#import "NetworkTypeUtils.h"
#import "NSObject+XYHUD.h"
#import "DownloadsTableViewModel.h"
#import "OSFileDownloaderManager.h"
#import "OSFileDownloaderManager.h"
#import "OSFileDownloadConst.h"
#import "UINavigationController+OSProgressBar.h"
#import "UIViewController+OSAlertExtension.h"
#import "NSString+OSFile.h"

@interface DownloadsViewController () <OSFileDownloaderDataSource>


@end

@implementation DownloadsViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - life cycle
////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self reloadTableData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    NSLog(@"%s", __func__);
}




- (void)setup {
    
    self.navigationItem.title = @"下载";
    self.tableViewModel = [DownloadsTableViewModel new];
    [self.tableViewModel prepareTableView:self.tableView];
    OSFileDownloaderManager *module = [OSFileDownloaderManager sharedInstance];
    module.shouldAutoDownloadWhenInitialize = YES;
    module.dataSource = self;
    [self addObservers];
    
    [self.tableView reloadData];
    
    [self reloadTableData];
    
    self.navigationController.progressView.progressHeight = 2.0;
    self.navigationController.progressView.progressTintColor = [UIColor redColor];
    self.navigationController.progressView.trackTintColor = [[UIColor greenColor] colorWithAlphaComponent:0.5];
    
}

- (void)reloadTableData {
    
    __weak typeof(self) weakSelf = self;
    [weakSelf.tableViewModel getDataSourceBlock:^id{
        NSArray *activeDownloadItems = [[OSFileDownloaderManager sharedInstance] activeDownloadItems];
        return @[activeDownloadItems];
    } completion:^{
        [weakSelf.tableView reloadData];
    }];
}


- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadSuccess:)
                                                 name:OSFileDownloadSussessNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadFailure:) name:OSFileDownloadFailureNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadProgressChange:) name:OSFileDownloadProgressChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadCanceld) name:OSFileDownloadCanceldNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableData) name:OSFileDownloaderResetDownloadsNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(totalProgressChange:) name:OSFileDownloadTotalProgressCanceldNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadStart:) name:OSFileDownloadStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableData) name:OSFileDownloadWaittingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableData) name:OSFileDownloadPausedNotification object:nil];
}




////////////////////////////////////////////////////////////////////////
#pragma mark - notifiy events
////////////////////////////////////////////////////////////////////////


- (void)downloadStart:(NSNotification *)note {
    [self reloadTableData];
}

- (void)downloadSuccess:(NSNotification *)note {
    
    [self reloadTableData];
}

- (void)downloadFailure:(NSNotification *)note {
    [self reloadTableData];
}

- (void)downloadProgressChange:(NSNotification *)note {
    
    OSFileItem *item = note.object;
    NSArray *downloadingArray = [[OSFileDownloaderManager sharedInstance] activeDownloadItems];
    NSUInteger foundIdxInDownloading = [downloadingArray indexOfObjectPassingTest:^BOOL(OSFileItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL res = [obj.urlPath isEqualToString:item.urlPath];
        if (res) {
            *stop = YES;
        }
        return res;
    }];
    
    NSArray *displayArray = [[OSFileDownloaderManager sharedInstance] displayItems];
    NSUInteger foundIdxInDisplay = [displayArray indexOfObjectPassingTest:^BOOL(OSFileItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL res = [obj.urlPath isEqualToString:item.urlPath];
        if (res) {
            *stop = YES;
        }
        return res;
    }];
    
    if (foundIdxInDownloading == NSNotFound && foundIdxInDisplay == NSNotFound) {
        return;
    }
    NSInteger row = foundIdxInDownloading != NSNotFound ? foundIdxInDownloading : foundIdxInDisplay;
    NSInteger section = foundIdxInDownloading != NSNotFound ? 0 : 1;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    DownloadsTableViewModel *tableViewModel = self.tableViewModel;
    OSFileDownloadCell *cell = [tableViewModel getDownloadCellByIndexPath:indexPath];
    cell.fileItem = item;
    
}

- (void)downloadCanceld {
    [self reloadTableData];
}

- (void)totalProgressChange:(NSNotification *)note {
    
    NSProgress *progress = note.object;
    [self.navigationController.progressView setProgress:progress.fractionCompleted animated:YES];
}


////////////////////////////////////////////////////////////////////////
#pragma mark - OSFileDownloaderDataSource
////////////////////////////////////////////////////////////////////////

- (NSArray<NSString *> *)OSFileDownloaderAddTasksFromRemoteURLPaths {
    return [self getImageUrls];
}

- (NSArray <NSString *> *)getImageUrls {
    return @[
//             @"http://sw.bos.baidu.com/sw-search-sp/software/447feea06f61e/QQ_mac_5.5.1.dmg",
//             @"http://sw.bos.baidu.com/sw-search-sp/software/9d93250a5f604/QQMusic_mac_4.2.3.dmg",
//             @"http://dlsw.baidu.com/sw-search-sp/soft/b4/25734/itunes12.3.1442478948.dmg",
//             @"http://sw.bos.baidu.com/sw-search-sp/software/40016db85afd8/thunder_mac_3.0.10.2930.dmg",
//             @"https://ss0.bdstatic.com/70cFvHSh_Q1YnxGkpoWK1HF6hhy/it/u=3494814264,3775539112&fm=21&gp=0.jpg",
//             @"https://ss3.bdstatic.com/70cFv8Sh_Q1YnxGkpoWK1HF6hhy/it/u=1996306967,4057581507&fm=21&gp=0.jpg",
//             @"https://ss0.bdstatic.com/70cFvHSh_Q1YnxGkpoWK1HF6hhy/it/u=2844924515,1070331860&fm=21&gp=0.jpg",
//             @"https://ss3.bdstatic.com/70cFv8Sh_Q1YnxGkpoWK1HF6hhy/it/u=3978900042,4167838967&fm=21&gp=0.jpg",
//             @"https://ss1.bdstatic.com/70cFvXSh_Q1YnxGkpoWK1HF6hhy/it/u=516632607,3953515035&fm=21&gp=0.jpg",
//             @"https://ss0.bdstatic.com/70cFuHSh_Q1YnxGkpoWK1HF6hhy/it/u=3180500624,3814864146&fm=21&gp=0.jpg",
//             @"https://ss0.bdstatic.com/70cFvHSh_Q1YnxGkpoWK1HF6hhy/it/u=3335283146,3705352490&fm=21&gp=0.jpg",
//             @"https://ss0.bdstatic.com/70cFvHSh_Q1YnxGkpoWK1HF6hhy/it/u=4090348863,2338325058&fm=21&gp=0.jpg",
//             @"https://ss0.bdstatic.com/70cFvHSh_Q1YnxGkpoWK1HF6hhy/it/u=3800219769,1402207302&fm=21&gp=0.jpg",
//             @"https://ss3.bdstatic.com/70cFv8Sh_Q1YnxGkpoWK1HF6hhy/it/u=1534694731,2880365143&fm=21&gp=0.jpg",
//             @"https://ss1.bdstatic.com/70cFvXSh_Q1YnxGkpoWK1HF6hhy/it/u=1155733552,156192689&fm=21&gp=0.jpg",
//             @"https://ss3.bdstatic.com/70cFv8Sh_Q1YnxGkpoWK1HF6hhy/it/u=3325163039,3163028420&fm=21&gp=0.jpg",
//             @"https://ss3.bdstatic.com/70cFv8Sh_Q1YnxGkpoWK1HF6hhy/it/u=2090484547,151176521&fm=21&gp=0.jpg",
//             @"https://ss2.bdstatic.com/70cFvnSh_Q1YnxGkpoWK1HF6hhy/it/u=2722857883,3187461130&fm=21&gp=0.jpg",
//             @"https://ss1.bdstatic.com/70cFvXSh_Q1YnxGkpoWK1HF6hhy/it/u=3443126769,3454865923&fm=21&gp=0.jpg",
//             @"https://ss3.bdstatic.com/70cFv8Sh_Q1YnxGkpoWK1HF6hhy/it/u=283169269,3942842194&fm=21&gp=0.jpg",
//             @"https://ss0.bdstatic.com/70cFvHSh_Q1YnxGkpoWK1HF6hhy/it/u=2522613626,1679950899&fm=21&gp=0.jpg",
//             @"https://ss0.bdstatic.com/70cFvHSh_Q1YnxGkpoWK1HF6hhy/it/u=2307958387,2904044619&fm=21&gp=0.jpg",
             ];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Lazy
////////////////////////////////////////////////////////////////////////

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.accessibilityIdentifier = [NSString stringWithFormat:@"%@-tableView", NSStringFromClass([self class])];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _tableView;
}


////////////////////////////////////////////////////////////////////////
#pragma mark - NoDataPlaceholderExtend
////////////////////////////////////////////////////////////////////////


- (NSAttributedString *)noDataReloadButtonAttributedStringWithState:(UIControlState)state {
    return [self attributedStringWithText:@"输入URL" color:[UIColor colorWithRed:49/255.0 green:194/255.0 blue:124/255.0 alpha:1.0] fontSize:15.0];
}

- (void)noDataPlaceholder:(UIScrollView *)scrollView didClickReloadButton:(UIButton *)button {
    [self alertControllerWithTitle:@"输入正确的URL"
                           message:nil
                           content:nil
                       placeholder:nil
                      keyboardType:UIKeyboardTypeURL
                               blk:^(UITextField *textField) {
                                   if ([textField.text hasPrefix:@"http"] || [textField.text hasPrefix:@"https"]) {
                                       NSString *urlPath = textField.text;
                                       /*
                                        解决URLWithString return nil问题
                                        原因：urlPath中可能存在空格导致
                                        */
                                       urlPath = [NSString returnFormatString:urlPath];
//                                       urlPath = [urlPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                                       [[OSFileDownloaderManager sharedInstance] start:urlPath];
                                   }
                                   else {
                                       [self alertControllerWithTitle:@"URL不是可下载资源，请检测后再确认哦！" message:nil okBlk:NULL];
                                   }
                                   [self reloadTableData];
                               }];
   
}

- (NSAttributedString *)noDataDetailLabelAttributedString {
    return [self attributedStringWithText:@"请输入URL开启下载任务" color:[UIColor grayColor] fontSize:16];
}

- (NSAttributedString *)noDataTextLabelAttributedString {
    return [self attributedStringWithText:@"无下载任务" color:[UIColor grayColor] fontSize:16];;
}

@end
