//
//  DownloadsTableViewModel.m
//  OSFileDownloader
//
//  Created by Ossey on 2017/6/12.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "DownloadsTableViewModel.h"
#import "AppDelegate.h"
#import "UITableViewCell+XYConfigure.h"
#import "UIView+Extend.h"
#import "OSFileDownloaderManager.h"

static NSString * const DownloadCellIdentifierKey = @"DownloadCellIdentifier";

@interface DownloadsTableViewModel ()

@property (nonatomic, weak) UITableView *tableView;

@end

@implementation DownloadsTableViewModel

////////////////////////////////////////////////////////////////////////
#pragma mark - XYTableViewModelProtocol
////////////////////////////////////////////////////////////////////////

- (void)prepareTableView:(UITableView *)tableView {
    tableView.delegate = self;
    tableView.dataSource = self;
    _tableView = tableView;
    [OSFileDownloadCell xy_registerTableViewCell:tableView classIdentifier:DownloadCellIdentifierKey];
}

- (void)getDataSourceBlock:(id (^)(void))dataSource completion:(void (^)(void))completion {
    if (dataSource) {
        self.dataSource = [dataSource() mutableCopy];
        
        if (completion) {
            completion();
        }
    }
}


////////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewDataSource
////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataSource.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return  [self.dataSource[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OSFileDownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:DownloadCellIdentifierKey forIndexPath:indexPath];
    NSArray *items = self.dataSource[indexPath.section];
    id<OSFileDownloadOperation> downloadItem = items[indexPath.row];
    [cell xy_configCellByModel:downloadItem indexPath:indexPath];
    __weak typeof(tableView) weaktableView = tableView;
    
    void (^alertBlock)(OSRemoteResourceItem *item) = ^(OSRemoteResourceItem *item) {
        UIAlertController *alVc = [UIAlertController alertControllerWithTitle:item.urlPath message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            UIAlertController *alVc = [UIAlertController alertControllerWithTitle:nil message:@"删除后文件将无法恢复" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                
                [[OSFileDownloaderManager sharedInstance] cancel:downloadItem.urlPath];
                [weaktableView reloadData];
                
            }];
            [alVc addAction:okAction];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:NULL];
            [alVc addAction:cancelAction];
            [[tableView currentViewController] presentViewController:alVc animated:YES completion:nil];
            
        }];
        [alVc addAction:okAction];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:NULL];
        [alVc addAction:cancelAction];
        [[tableView currentViewController] presentViewController:alVc animated:YES completion:nil];
    };
    
    [cell setLongPressGestureRecognizer:^(UILongPressGestureRecognizer *longPres) {
        OSFileDownloadCell *cell = (OSFileDownloadCell *)longPres.view;
        if (longPres.state == UIGestureRecognizerStateBegan) {
            alertBlock(cell.fileItem);
        }
    }];
    
    [cell setOptionButtonClick:^(UIButton *btn, OSFileDownloadCell *cell) {
        alertBlock(cell.fileItem);
    }];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 70;
}


////////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewDelegate
////////////////////////////////////////////////////////////////////////

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    OSFileDownloadCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.fileItem.status == OSFileDownloadStatusNotStarted) {
        [self performSelector:@selector(scrollToIndexPath:) withObject:[NSIndexPath indexPathForRow:0 inSection:0] afterDelay:0.0];
    }
    [cell cycleViewClick:nil];
}

- (void)scrollToIndexPath:(NSIndexPath *)indexpath {
    [self.tableView scrollToRowAtIndexPath:indexpath atScrollPosition:UITableViewScrollPositionNone animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        if ([self.dataSource[section] count]) {
            return @"缓存任务";
        } else {
            return @"";
        }
    }
    return @"";
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

- (OSFileDownloadCell *)getDownloadCellByIndexPath:(NSIndexPath *)indexPath {
    return [self.tableView cellForRowAtIndexPath:indexPath];
}


@end
