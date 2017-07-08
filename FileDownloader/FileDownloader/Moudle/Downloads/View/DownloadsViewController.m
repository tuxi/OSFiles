//
//  DownloadsViewController.m
//  FileDownloader
//
//  Created by Ossey on 2017/6/10.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "DownloadsViewController.h"
#import "NetworkTypeUtils.h"
#import "NSObject+XYHUD.h"
#import "DownloadsTableViewModel.h"
#import "OSDownloaderModule.h"
#import "OSFileItem.h"
#import "OSDownloaderModule.h"

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

#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ life cycle ~~~~~~~~~~~~~~~~~~~~~~~

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setup];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    NSLog(@"%s", __func__);
}

#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ initialize ~~~~~~~~~~~~~~~~~~~~~~~


- (void)setup {
    
    self.navigationItem.title = @"Downloads";
    self.tableViewModel = [DownloadsTableViewModel new];
    [self.tableViewModel prepareTableView:self.tableView];
    OSDownloaderModule *module = [OSDownloaderModule sharedInstance];
    module.dataSource = self;
    [self addObservers];
    
    [self.tableView reloadData];
    
    
    
    [self reloadBlock]();
    
    self.tableView.reloadButtonClickBlock = [self reloadBlock];
    
}

- (void (^)())reloadBlock {
    
    __weak typeof(self) weakSelf = self;
    __weak OSDownloaderModule *weakMoudle = [OSDownloaderModule sharedInstance];
    void (^reloadBlock)() = ^{
        
        [weakSelf.tableViewModel getDataSourceBlock:^id{
            NSArray *activeDownloadItems = [weakMoudle getActiveDownloadItems];
            NSArray *displayItems = [weakMoudle displayItems];
            return @[activeDownloadItems, displayItems];
        } completion:^{
            [weakSelf.tableView reloadData];
        }];
        
    };
    return reloadBlock;
}

- (void)reloadTableView {
    [self reloadBlock]();
}

- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadSuccess:) name:OSFileDownloadSussessNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadFailure:) name:OSFileDownloadFailureNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadProgressChange:) name:OSFileDownloadProgressChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadCanceld) name:OSFileDownloadCanceldNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableView) name:FileDownloaderResetDownloadsNotification object:nil];
}




#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ notifiy events ~~~~~~~~~~~~~~~~~~~~~~~


- (void)downloadSuccess:(NSNotification *)note {
    
    [self reloadBlock]();
}

- (void)downloadFailure:(NSNotification *)note {
    [self reloadBlock]();
}

- (void)downloadProgressChange:(NSNotification *)note {
    
    [self reloadBlock]();
    
}

- (void)downloadCanceld {
    [self reloadBlock]();
}



#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ <OSFileDownloaderDataSource> ~~~~~~~~~~~~~~~~~~~~~~~

- (NSArray<NSString *> *)fileDownloaderAddTasksFromRemoteURLPaths {
    return [self getImageUrls];
}

- (NSArray <NSString *> *)getImageUrls {
    return @[
             
             @"http://sw.bos.baidu.com/sw-search-sp/software/447feea06f61e/QQ_mac_5.5.1.dmg",
             @"http://sw.bos.baidu.com/sw-search-sp/software/9d93250a5f604/QQMusic_mac_4.2.3.dmg",
             @"http://dlsw.baidu.com/sw-search-sp/soft/b4/25734/itunes12.3.1442478948.dmg",
             @"http://sw.bos.baidu.com/sw-search-sp/software/40016db85afd8/thunder_mac_3.0.10.2930.dmg",
             /*
              @"https://ss0.bdstatic.com/70cFvHSh_Q1YnxGkpoWK1HF6hhy/it/u=3494814264,3775539112&fm=21&gp=0.jpg",
              @"https://ss3.bdstatic.com/70cFv8Sh_Q1YnxGkpoWK1HF6hhy/it/u=1996306967,4057581507&fm=21&gp=0.jpg",
              @"https://ss0.bdstatic.com/70cFvHSh_Q1YnxGkpoWK1HF6hhy/it/u=2844924515,1070331860&fm=21&gp=0.jpg",
              @"https://ss3.bdstatic.com/70cFv8Sh_Q1YnxGkpoWK1HF6hhy/it/u=3978900042,4167838967&fm=21&gp=0.jpg",
              @"https://ss1.bdstatic.com/70cFvXSh_Q1YnxGkpoWK1HF6hhy/it/u=516632607,3953515035&fm=21&gp=0.jpg",
              @"https://ss0.bdstatic.com/70cFuHSh_Q1YnxGkpoWK1HF6hhy/it/u=3180500624,3814864146&fm=21&gp=0.jpg",
              @"https://ss0.bdstatic.com/70cFvHSh_Q1YnxGkpoWK1HF6hhy/it/u=3335283146,3705352490&fm=21&gp=0.jpg",
              @"https://ss0.bdstatic.com/70cFvHSh_Q1YnxGkpoWK1HF6hhy/it/u=4090348863,2338325058&fm=21&gp=0.jpg",
              @"https://ss0.bdstatic.com/70cFvHSh_Q1YnxGkpoWK1HF6hhy/it/u=3800219769,1402207302&fm=21&gp=0.jpg",
              @"https://ss3.bdstatic.com/70cFv8Sh_Q1YnxGkpoWK1HF6hhy/it/u=1534694731,2880365143&fm=21&gp=0.jpg",
              @"https://ss1.bdstatic.com/70cFvXSh_Q1YnxGkpoWK1HF6hhy/it/u=1155733552,156192689&fm=21&gp=0.jpg",
              @"https://ss3.bdstatic.com/70cFv8Sh_Q1YnxGkpoWK1HF6hhy/it/u=3325163039,3163028420&fm=21&gp=0.jpg",
              @"https://ss3.bdstatic.com/70cFv8Sh_Q1YnxGkpoWK1HF6hhy/it/u=2090484547,151176521&fm=21&gp=0.jpg",
              @"https://ss2.bdstatic.com/70cFvnSh_Q1YnxGkpoWK1HF6hhy/it/u=2722857883,3187461130&fm=21&gp=0.jpg",
              @"https://ss1.bdstatic.com/70cFvXSh_Q1YnxGkpoWK1HF6hhy/it/u=3443126769,3454865923&fm=21&gp=0.jpg",
              @"https://ss3.bdstatic.com/70cFv8Sh_Q1YnxGkpoWK1HF6hhy/it/u=283169269,3942842194&fm=21&gp=0.jpg",
              @"https://ss0.bdstatic.com/70cFvHSh_Q1YnxGkpoWK1HF6hhy/it/u=2522613626,1679950899&fm=21&gp=0.jpg",
              @"https://ss0.bdstatic.com/70cFvHSh_Q1YnxGkpoWK1HF6hhy/it/u=2307958387,2904044619&fm=21&gp=0.jpg",
              */
             ];
}

#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ Lazy ~~~~~~~~~~~~~~~~~~~~~~~

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.accessibilityIdentifier = [NSString stringWithFormat:@"%@-tableView", NSStringFromClass([self class])];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _tableView;
}


#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ Config NoDataPlaceholderExtend ~~~~~~~~~~~~~~~~~~~~~~~

- (NSAttributedString *)titleAttributedStringForNoDataPlaceholder {
    
    NSString *text = @"当前无下载任务";
    
    UIFont *font = nil;
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_4) {
        font = [UIFont monospacedDigitSystemFontOfSize:18.0 weight:UIFontWeightRegular];
    } else {
        font = [UIFont boldSystemFontOfSize:18.0];
    }
    UIColor *textColor = [UIColor redColor];
    
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

- (NSAttributedString *)detailAttributedStringForNoDataPlaceholder {
    NSString *text = @"可以输入URL下载哦";
    
    UIFont *font = nil;
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_4) {
        font = [UIFont monospacedDigitSystemFontOfSize:18.0 weight:UIFontWeightRegular];
    } else {
        font = [UIFont boldSystemFontOfSize:18.0];
    }
    UIColor *textColor = [UIColor redColor];
    
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
    
    NSString *text = @"输入URL";
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

- (UIImage *)noDataPlaceholderImageWithIsLoading:(BOOL)isLoading {
    if (isLoading) {
        return [super noDataPlaceholderImageWithIsLoading:isLoading];
    } else {
        UIImage *image = [UIImage imageNamed:@"downloadIcon"];
        return image;
    }
}




@end
