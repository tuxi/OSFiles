//
//  FilesTableViewModel.m
//  FileDownloader
//
//  Created by Ossey on 2017/6/12.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "FilesTableViewModel.h"
#import "AppDelegate.h"
#import "OSFileDownloadCell.h"

static NSString * const FilesViewControllerViewCellID = @"FilesViewController";

@implementation FilesTableViewModel

- (void)prepareTableView:(UITableView *)tableView {
    tableView.delegate = self;
    tableView.dataSource = self;
    [tableView registerClass:[OSFileDownloadCell class] forCellReuseIdentifier:FilesViewControllerViewCellID];
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

@end
