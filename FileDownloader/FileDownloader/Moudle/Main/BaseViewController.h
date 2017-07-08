//
//  BaseViewController.h
//  FileDownloader
//
//  Created by Ossey on 2017/6/10.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableView+NoDataPlaceholderExtend.h"
#import "XYTableViewModelProtocol.h"

@interface BaseViewController : UIViewController {
    UITableView *_tableView;
}

@property (nonatomic, strong) id<XYTableViewModelProtocol> tableViewModel;

@property (nonatomic, strong) UITableView *tableView;

- (BOOL)shouldShowNoDataPlaceholder;

- (UIImage *)noDataPlaceholderImageWithIsLoading:(BOOL)isLoading;
- (NSAttributedString *)reloadbuttonTitleAttributedStringForNoDataPlaceholder;
- (NSAttributedString *)detailAttributedStringForNoDataPlaceholder;
- (NSAttributedString *)titleAttributedStringForNoDataPlaceholder;
@end
