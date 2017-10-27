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

- (void)getDataSourceBlock:(id (^)(void))dataSource completion:(void (^)())completion {
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
    [cell setLongPressGestureRecognizer:^(UILongPressGestureRecognizer *longPres) {
        if (longPres.state == UIGestureRecognizerStateBegan) {
            UIAlertController *alVc = [UIAlertController alertControllerWithTitle:@"delete download" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
                [[OSFileDownloaderManager sharedInstance] cancel:downloadItem.urlPath];
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
            return @"downloading tasks";
        } else {
            return @"";
        }
    }
    if (section == 1) {
        if ([self.dataSource[section] count]) {
            return @"display files";
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
