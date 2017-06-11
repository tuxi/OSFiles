//
//  FilesViewController.m
//  FileDownloader
//
//  Created by Ossey on 2017/6/10.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "FilesViewController.h"
#import "AppDelegate.h"
#import "OSFileDownloadCell.h"

static NSString * const FilesViewControllerViewCellID = @"FilesViewController";

@interface FilesViewController ()

@end

@implementation FilesViewController

#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ Life cycle ~~~~~~~~~~~~~~~~~~~~~~~

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
    [self initTableView];
    [self addObservers];
}

- (void)initTableView {
    
    [self.tableView registerClass:[OSFileDownloadCell class] forCellReuseIdentifier:FilesViewControllerViewCellID];
}

- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadSuccess:) name:OSFileDownloadSussessNotification object:nil];
}

#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ Notify ~~~~~~~~~~~~~~~~~~~~~~~

- (void)downloadSuccess:(NSNotification *)noti {
    [self.tableView reloadData];
}

#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ Table view data source ~~~~~~~~~~~~~~~~~~~~~~~


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    return [delegate.downloadModule getAllSuccessItems].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OSFileDownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:FilesViewControllerViewCellID forIndexPath:indexPath];
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    cell.downloadItem = [delegate.downloadModule getAllSuccessItems][indexPath.row];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 60;
}



#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ Config NoDataPlaceholderExtend ~~~~~~~~~~~~~~~~~~~~~~~

- (NSAttributedString *)titleAttributedStringForNoDataPlaceholder {
    
    NSString *text = @"本地无下载文件";
    
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



@end
