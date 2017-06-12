//
//  BaseTableViewModel.m
//  FileDownloader
//
//  Created by Ossey on 2017/6/12.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "BaseTableViewModel.h"

@implementation BaseTableViewModel

- (void)prepareTableView:(UITableView *)tableView {
    tableView.delegate = self;
    tableView.dataSource = self;
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"baseCell"];
}


#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ Table view data source ~~~~~~~~~~~~~~~~~~~~~~~


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 60;
}

@end
