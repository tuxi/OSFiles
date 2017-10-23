//
//  BaseTableViewModel.m
//  OSFileDownloader
//
//  Created by Ossey on 2017/6/12.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "BaseTableViewModel.h"

@interface BaseTableViewModel ()

@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation BaseTableViewModel

- (void)prepareTableView:(UITableView *)tableView {
    tableView.delegate = self;
    tableView.dataSource = self;
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"baseCell"];
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
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
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 60;
}

- (NSMutableArray *)dataSource {
    if (!_dataSource) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

@end
