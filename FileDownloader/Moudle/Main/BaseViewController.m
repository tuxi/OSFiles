//
//  BaseViewController.m
//  OSFileDownloader
//
//  Created by Ossey on 2017/6/10.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "BaseViewController.h"
#import "BaseTableViewModel.h"

@interface BaseViewController ()

@end

@implementation BaseViewController

////////////////////////////////////////////////////////////////////////
#pragma mark - Life cryle
////////////////////////////////////////////////////////////////////////


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
    [self.tableViewModel prepareTableView:self.tableView];
}


- (void)makeViewConstraints {
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:nil views:@{@"tableView": _tableView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|" options:0 metrics:nil views:@{@"tableView": _tableView}]];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


////////////////////////////////////////////////////////////////////////
#pragma mark - Public
////////////////////////////////////////////////////////////////////////

- (BOOL)shouldShowNoDataPlaceholder {
    return YES;
}



////////////////////////////////////////////////////////////////////////
#pragma mark - Config NoDataPlaceholderExtend
////////////////////////////////////////////////////////////////////////

- (void)usingNoDataPlaceholder {
    [self.tableView usingNoDataPlaceholder];
    [self setupNoDataPlaceholder];
//    __weak typeof(self) weakSelf = self;
//    self.tableView.reloadButtonClickBlock = ^{
//        [weakSelf getDataFromNetwork];
//    };
    
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
    
    return nil;
    
}

- (NSAttributedString *)reloadbuttonTitleAttributedStringForNoDataPlaceholder {
    
    UIFont *font = nil;
    
    NSString *text = @"输入URL";
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_4) {
        font = [UIFont monospacedDigitSystemFontOfSize:15.0 weight:UIFontWeightRegular];
    } else {
        font = [UIFont boldSystemFontOfSize:15.0];
    }
    UIColor *textColor = [UIColor whiteColor];
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



////////////////////////////////////////////////////////////////////////
#pragma mark - Lazy
////////////////////////////////////////////////////////////////////////

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.accessibilityIdentifier = [NSString stringWithFormat:@"%@-tableView", NSStringFromClass([self class])];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _tableView;
}

- (id<XYTableViewModelProtocol>)tableViewModel {
    if (!_tableViewModel) {
        _tableViewModel = [BaseTableViewModel new];
    }
    return _tableViewModel;
}

@end
