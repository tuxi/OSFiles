//
//  FilesTableViewModel.m
//  FileDownloader
//
//  Created by Ossey on 2017/6/12.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "FilesTableViewModel.h"
#import "OSFileDownloadCell.h"
#import "XYImageViewer.h"
#import "OSFileItem.h"
#import "XYCutVideoController.h"
#import "UIView+Extend.h"

static NSString * const FilesViewControllerViewCellID = @"FilesViewController";

@interface FilesTableViewModel()

@property (nonatomic, weak) UITableView *tableView;

@end

@implementation FilesTableViewModel

- (void)prepareTableView:(UITableView *)tableView {
    tableView.delegate = self;
    tableView.dataSource = self;
    _tableView = tableView;
    [tableView registerClass:[OSFileDownloadCell class] forCellReuseIdentifier:FilesViewControllerViewCellID];
}

#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ XYTableViewModelProtocol ~~~~~~~~~~~~~~~~~~~~~~~

- (void)getDataSourceBlock:(id (^)())dataSource completion:(void (^)())completion {
    if (dataSource) {
        self.dataSource = [dataSource() mutableCopy];
        
        if (completion) {
            completion();
        }
    }
}



#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ UITableViewDataSource ~~~~~~~~~~~~~~~~~~~~~~~


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OSFileDownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:FilesViewControllerViewCellID forIndexPath:indexPath];
    cell.downloadItem = self.dataSource[indexPath.row];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 60;
}

#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ UITableViewDelegate ~~~~~~~~~~~~~~~~~~~~~~~

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self openFileWithIndexPath:indexPath];

}


- (void)openFileWithIndexPath:(NSIndexPath *)indexPath {
    
    [self seeImageWithIndexPath:indexPath];
    
    [self cutVideoWithIndexPath:indexPath];
}

- (void)cutVideoWithIndexPath:(NSIndexPath *)indexPath {
    
    OSFileItem *item = (OSFileItem *)self.dataSource[indexPath.row];
    // _MIMEType	NSTaggedPointerString *	@"video/mp4"	0xa2304a003f0625c9
    if ([item.MIMEType isEqualToString:@"video/mp4"]) {
        XYCutVideoController *vc = [XYCutVideoController new];
        vc.videoURL = item.localFolderURL;
        [[self.tableView visibleViewController].navigationController pushViewController:vc animated:YES];
    }
    
    
}



// 查看图片
- (void)seeImageWithIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
//    NSMutableArray *imageURLs = [NSMutableArray array];
//    [self.dataSource enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        OSFileItem *item = (OSFileItem *)obj;
//        if ([item isKindOfClass:[OSFileItem class]]) {
//            if ([item.MIMEType isEqualToString:@"image/jpeg"] || [item.MIMEType isEqualToString:@"image/png"]) {
//                [imageURLs addObject:item.urlPath];
//            }
//        }
//    }];
    
    OSFileItem *item = (OSFileItem *)self.dataSource[indexPath.row];
    
    if ([item.MIMEType isEqualToString:@"image/jpeg"] || [item.MIMEType isEqualToString:@"image/png"]) {
        [[XYImageViewer prepareImages:@[item.localFolderURL.path] pageTextList:nil endView:^UIView *(NSIndexPath *indexPath) {
            return [self.tableView cellForRowAtIndexPath:indexPath];
        }] show:cell currentIndex:0];
        
    }
}

- (void)playVideoWithIndexPath:(NSIndexPath *)indexPath {

}

@end
