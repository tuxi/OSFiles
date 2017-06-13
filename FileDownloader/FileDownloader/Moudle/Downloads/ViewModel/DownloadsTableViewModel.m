//
//  DownloadsTableViewModel.m
//  FileDownloader
//
//  Created by Ossey on 2017/6/12.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "DownloadsTableViewModel.h"
#import "OSFileDownloadCell.h"
#import "AppDelegate.h"
#import "OSFileItem.h"
#import "UITableViewCell+XYConfigure.h"
#import "UIView+Extend.h"

static NSString * const DownloadCellIdentifierKey = @"DownloadCellIdentifier";

@implementation DownloadsTableViewModel

- (void)prepareTableView:(UITableView *)tableView {
    tableView.delegate = self;
    tableView.dataSource = self;
    [OSFileDownloadCell xy_registerTableViewCell:tableView classIdentifier:DownloadCellIdentifierKey];
}

#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ UITableViewDataSource ~~~~~~~~~~~~~~~~~~~~~~~


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    return [delegate.downloadModule getDownloadingItems].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OSFileDownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:DownloadCellIdentifierKey forIndexPath:indexPath];
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    OSFileItem *downloadItem = [delegate.downloadModule getDownloadingItems][indexPath.row];
    [cell xy_configCellByModel:downloadItem indexPath:indexPath];
    [cell setLongPressGestureRecognizer:^(UILongPressGestureRecognizer *longPres) {
        if (longPres.state == UIGestureRecognizerStateBegan) {
            UIAlertController *alVc = [UIAlertController alertControllerWithTitle:@"delete download" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
                [delegate.downloadModule cancel:downloadItem.urlPath];
                [tableView reloadData];
                
            }];
            [alVc addAction:okAction];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            [alVc addAction:cancelAction];
            [[tableView currentViewController] presentViewController:alVc animated:YES completion:nil];;
        }
    }];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 60;
}

#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ UITableViewDelegate ~~~~~~~~~~~~~~~~~~~~~~~

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}


@end
