//
//  OSAboutAppViewController.m
//  FileDownloader
//
//  Created by Swae on 2017/11/10.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSAboutAppViewController.h"

@interface OSAboutAppViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary<NSString *, NSString *> *> *dataArray;

@end

@implementation OSAboutAppViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"关于";
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    // app名称
    NSString *app_Name = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    // app版本
    NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    // app build版本
    NSString *app_build = [infoDictionary objectForKey:@"CFBundleVersion"];
    
    _dataArray = @[
                   @{@"名称": app_Name},
                   @{@"软件版本": app_Version},
                   @{@"App build版本": app_build},
                   
                   ];
    [self.view addSubview:self.tableView];
    [self makeViewConstraints];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * const cellIdentifier = @"OSAboutAppViewControllerCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    }
    
    NSDictionary *dict = _dataArray[indexPath.row];
    cell.textLabel.text = dict.allKeys.firstObject;
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.detailTextLabel.text = dict.allValues.firstObject;
    cell.detailTextLabel.textAlignment = NSTextAlignmentRight;
    return cell;
}

- (void)makeViewConstraints {
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:nil views:@{@"tableView": _tableView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|" options:0 metrics:nil views:@{@"tableView": _tableView}]];
}


- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.accessibilityIdentifier = [NSString stringWithFormat:@"%@-tableView", NSStringFromClass([self class])];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _tableView;
}

@end
