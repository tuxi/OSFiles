//
//  OSBaseViewController.m
//  OSFileDownloader
//
//  Created by Ossey on 2017/6/10.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSBaseViewController.h"
#import "BaseTableViewModel.h"

@interface OSBaseViewController () <NoDataPlaceholderDelegate>

@end

@implementation OSBaseViewController

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
    [self setupNodataView];
}

- (void)setupNodataView {
    __weak typeof(self) weakSelf = self;
    
    self.tableView.noDataPlaceholderDelegate = self;
    
    self.tableView.customNoDataView = ^UIView * _Nonnull{
        if (weakSelf.tableView.xy_loading) {
            UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [activityView startAnimating];
            return activityView;
        }
        else {
            return nil;
        }
        
    };
    
    self.tableView.noDataTextLabelBlock = ^(UILabel * _Nonnull textLabel) {
        NSAttributedString *string = [weakSelf noDataTextLabelAttributedString];
        if (!string.length) {
            return;
        }
        textLabel.backgroundColor = [UIColor clearColor];
        textLabel.font = [UIFont systemFontOfSize:27.0];
        textLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
        textLabel.textAlignment = NSTextAlignmentCenter;
        textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        textLabel.numberOfLines = 0;
        textLabel.attributedText = string;
    };
    
    self.tableView.noDataDetailTextLabelBlock = ^(UILabel * _Nonnull detailTextLabel) {
        NSAttributedString *string = [weakSelf noDataDetailLabelAttributedString];
        if (!string.length) {
            return;
        }
        detailTextLabel.backgroundColor = [UIColor clearColor];
        detailTextLabel.font = [UIFont systemFontOfSize:17.0];
        detailTextLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
        detailTextLabel.textAlignment = NSTextAlignmentCenter;
        detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        detailTextLabel.numberOfLines = 0;
        detailTextLabel.attributedText = string;
    };
    
    
    
    self.tableView.noDataImageViewBlock = ^(UIImageView * _Nonnull imageView) {
        imageView.backgroundColor = [UIColor clearColor];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.userInteractionEnabled = NO;
        imageView.image = [weakSelf noDataImageViewImage];
        
    };
    
    
    self.tableView.noDataReloadButtonBlock = ^(UIButton * _Nonnull reloadButton) {
        reloadButton.backgroundColor = [UIColor clearColor];
        reloadButton.layer.borderWidth = 0.5;
        reloadButton.layer.borderColor = [UIColor colorWithRed:49/255.0 green:194/255.0 blue:124/255.0 alpha:1.0].CGColor;
        reloadButton.layer.cornerRadius = 2.0;
        [reloadButton.layer setMasksToBounds:YES];
        [reloadButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [reloadButton setAttributedTitle:[weakSelf noDataReloadButtonAttributedStringWithState:UIControlStateNormal] forState:UIControlStateNormal];
    };
    
    
    self.tableView.noDataTextEdgeInsets = UIEdgeInsetsMake(20, 0, 20, 0);
    self.tableView.noDataButtonEdgeInsets = UIEdgeInsetsMake(20, 100, 11, 100);
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
#pragma mark - NoDataPlaceholderDelegate
////////////////////////////////////////////////////////////////////////

- (void)noDataPlaceholder:(UIScrollView *)scrollView didClickReloadButton:(UIButton *)button {
    [self didClickDataPlaceholderReloadButton:button];
}

- (BOOL)noDataPlaceholderShouldAllowScroll:(UIScrollView *)scrollView {
    return YES;
}

- (void)noDataPlaceholder:(UIScrollView *)scrollView didTapOnContentView:(UITapGestureRecognizer *)tap {
    [self didTapOnDataPlaceholderContentView:tap];
}

- (void)didTapOnDataPlaceholderContentView:(UITapGestureRecognizer *)tap {
    
}

- (CGPoint)contentOffsetForNoDataPlaceholder:(UIScrollView *)scrollView {
    if ([UIDevice currentDevice].orientation == UIDeviceOrientationPortrait) {
        return CGPointMake(0, 120.0);
    }
    return CGPointMake(0.0, 80.0);
}

- (void)noDataPlaceholderWillAppear:(UIScrollView *)scrollView {
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
}

- (void)noDataPlaceholderDidDisappear:(UIScrollView *)scrollView {
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
}

- (BOOL)noDataPlaceholderShouldFadeInOnDisplay:(UIScrollView *)scrollView {
    return YES;
}

- (NSAttributedString *)noDataReloadButtonAttributedStringWithState:(UIControlState)state {
    return nil;
}

- (NSAttributedString *)noDataDetailLabelAttributedString {
    return nil;
}

- (NSAttributedString *)noDataTextLabelAttributedString {
    return nil;
}

- (UIImage *)noDataImageViewImage {
    return [UIImage imageNamed:@"file_noData"];
}

- (NSAttributedString *)attributedStringWithText:(NSString *)string color:(UIColor *)color fontSize:(CGFloat)fontSize {
    NSString *text = string;
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    UIColor *textColor = color;
    
    NSMutableDictionary *attributeDict = [NSMutableDictionary new];
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.lineBreakMode = NSLineBreakByWordWrapping;
    style.alignment = NSTextAlignmentCenter;
    style.lineSpacing = 4.0;
    [attributeDict setObject:font forKey:NSFontAttributeName];
    [attributeDict setObject:textColor forKey:NSForegroundColorAttributeName];
    [attributeDict setObject:style forKey:NSParagraphStyleAttributeName];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:attributeDict];
    
    return attributedString;
    
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
