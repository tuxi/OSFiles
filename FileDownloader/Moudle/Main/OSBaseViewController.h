//
//  OSBaseViewController.h
//  OSFileDownloader
//
//  Created by Ossey on 2017/6/10.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIScrollView+NoDataExtend.h>
#import "XYTableViewModelProtocol.h"

@interface OSBaseViewController : UIViewController {
    UITableView *_tableView;
}

@property (nonatomic, strong) id<XYTableViewModelProtocol> tableViewModel;

@property (nonatomic, strong) UITableView *tableView;

- (NSAttributedString *)attributedStringWithText:(NSString *)string color:(UIColor *)color fontSize:(CGFloat)fontSize;

/// 子类可以重写此方法
- (void)noDataPlaceholder:(UIScrollView *)scrollView didClickReloadButton:(UIButton *)button;
- (void)noDataPlaceholder:(UIScrollView *)scrollView didTapOnContentView:(UITapGestureRecognizer *)tap;
- (NSAttributedString *)noDataReloadButtonAttributedStringWithState:(UIControlState)state;
- (NSAttributedString *)noDataDetailLabelAttributedString;
- (NSAttributedString *)noDataTextLabelAttributedString;
- (UIImage *)noDataImageViewImage;
@end
