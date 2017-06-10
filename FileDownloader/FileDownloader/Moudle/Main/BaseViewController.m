//
//  BaseViewController.m
//  FileDownloader
//
//  Created by Ossey on 2017/6/10.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "BaseViewController.h"


@interface BaseViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, assign) NSInteger currentClickRow;

@end

@implementation BaseViewController

#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ Life cryle ~~~~~~~~~~~~~~~~~~~~~~~


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self baseSetupUI];

}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    if ([self shouldShowNoDataPlaceholder]) {
        [self usingNoDataPlaceholder];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    [self makeViewConstraints];
}

- (void)baseSetupUI {
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;

}


- (void)makeViewConstraints {
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:nil views:@{@"tableView": _tableView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|" options:0 metrics:nil views:@{@"tableView": _tableView}]];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ Public ~~~~~~~~~~~~~~~~~~~~~~~

- (BOOL)shouldShowNoDataPlaceholder {
    return YES;
}



#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ UITableViewDataSource ~~~~~~~~~~~~~~~~~~~~~~~

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return _dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }

    if (indexPath.row == 0) {
        cell.textLabel.text = @"添加10条数据";
    } else if (indexPath.row == 1) {
        cell.textLabel.text = @"删除全部数据";
    } else {
        cell.textLabel.text = [NSString stringWithFormat:@"删除第%ld行",indexPath.row];
    }
    
    cell.backgroundColor = [UIColor colorWithRed:arc4random_uniform(256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:1.0];
    
    
    return cell;
}


#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ UITableViewDelegate ~~~~~~~~~~~~~~~~~~~~~~~

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    _currentClickRow = indexPath.row;
    [[[UIAlertView alloc] initWithTitle:@"请选择" message:nil delegate:self cancelButtonTitle:@"不" otherButtonTitles:@"好的", nil] show];
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.accessibilityIdentifier = [NSString stringWithFormat:@"%@-tableView", NSStringFromClass([self class])];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _tableView;
}

#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ Config NoDataPlaceholderExtend ~~~~~~~~~~~~~~~~~~~~~~~

- (void)usingNoDataPlaceholder {
    [self.tableView usingNoDataPlaceholder];
    [self setupNoDataPlaceholder];
    __weak typeof(self) weakSelf = self;
    self.tableView.reloadButtonClickBlock = ^{
        [weakSelf getDataFromNetwork];
    };
    
}

- (void)setupNoDataPlaceholder {
    self.tableView.noDataPlaceholderTitleAttributedString = [self titleAttributedStringForNoDataPlaceholder];
    self.tableView.noDataPlaceholderDetailAttributedString = [self detailAttributedStringForNoDataPlaceholder];
    self.tableView.noDataPlaceholderReloadbuttonAttributedString = [self reloadbuttonTitleAttributedStringForNoDataPlaceholder];
    self.tableView.noDataPlaceholderLoadingImage = [self noDataPlaceholderImageWithIsLoading:YES];
    self.tableView.noDataPlaceholderNotLoadingImage = [self noDataPlaceholderImageWithIsLoading:NO];
}

- (NSAttributedString *)titleAttributedStringForNoDataPlaceholder {
    
    NSString *text = @"没有数据";
    
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
    
    UIFont *font = nil;
    UIColor *textColor = nil;
    
    NSMutableDictionary *attributeDict = [NSMutableDictionary new];
    
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.lineBreakMode = NSLineBreakByWordWrapping;
    style.alignment = NSTextAlignmentCenter;
    NSString *text = @"快输入URL下载你喜欢的大片!";
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_4) {
        font = [UIFont monospacedDigitSystemFontOfSize:16.0 weight:UIFontWeightRegular];
    } else {
        font = [UIFont boldSystemFontOfSize:16.0];
    }
    
    textColor = [UIColor blueColor];
    style.lineSpacing = 4.0;
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
    UIColor *textColor = [UIColor blackColor];
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    if (font) [attributes setObject:font forKey:NSFontAttributeName];
    if (textColor) [attributes setObject:textColor forKey:NSForegroundColorAttributeName];
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)noDataPlaceholderImageWithIsLoading:(BOOL)isLoading {
    if (isLoading) {
        return [UIImage imageNamed:@"loading_imgBlue_78x78" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    } else {
        UIImage *image = [UIImage imageNamed:@"placeholder_instagram"];
        return image;
    }
}

#pragma mark - <UIAlertViewDelegate>

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        
        if (_currentClickRow == 0) {
            [self addData];
        } else if (_currentClickRow == 1) {
            [_dataSource removeAllObjects];
        } else {
            if (_currentClickRow < _dataSource.count) {
                [_dataSource removeObjectAtIndex:_currentClickRow];
            } else {
                NSAssert(_currentClickRow < _dataSource.count, @"要删除的数据索引超出了数组的长度");
            }
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }
}


#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ other ~~~~~~~~~~~~~~~~~~~~~~~

- (NSMutableArray *)dataSource {
    if (!_dataSource) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

- (void)getDataFromNetwork {
    
    self.tableView.loading = YES;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self addData];
        self.tableView.loading = NO;
        [self.tableView reloadData];
    });
}

- (void)addData {
    int i = 0;
    while (i < 10) {
        
        [[self dataSource] addObject:[NSString stringWithFormat:@"%d", i]];
        
        i++;
    }
    
}
@end
