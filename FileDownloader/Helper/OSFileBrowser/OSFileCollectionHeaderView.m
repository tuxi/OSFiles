//
//  OSFileCollectionHeaderView.m
//  FileDownloader
//
//  Created by Swae on 2017/11/19.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileCollectionHeaderView.h"
#import "UIImage+XYImage.h"

NSString * const OSFileCollectionHeaderViewDefaultIdentifier = @"UICollectionReusableView";

@interface OSFileCollectionHeaderView ()

@property (nonatomic, strong) UIButton *searchButton;
@property (nonatomic, strong) UIButton *changeStyleButton;
@property (nonatomic, strong) UISegmentedControl *sortControl;

@end

@implementation OSFileCollectionHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithRed:31/255.0 green:31/255.0 blue:31/255.0 alpha:1.0];
        [self setupViews];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sortTypeChangeNotification:) name:OSFileBrowserAppearanceConfigsSortTypeDidChangeNotification object:nil];
    }
    return self;
}

- (void)setupViews {
    [self addSubview:self.searchButton];
    [self addSubview:self.changeStyleButton];
    [self addSubview:self.sortControl];
    
    CGFloat iconWidth = 26.0;
    NSLayoutConstraint *searchBtnCenterY = [NSLayoutConstraint constraintWithItem:self.searchButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
     NSLayoutConstraint *searchBtnLeft = [NSLayoutConstraint constraintWithItem:self.searchButton attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:10.0];
    NSLayoutConstraint *searchBtnWidth = [NSLayoutConstraint constraintWithItem:self.searchButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:iconWidth];
    NSLayoutConstraint *searchBtnHeight = [NSLayoutConstraint constraintWithItem:self.searchButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:iconWidth];
    [NSLayoutConstraint activateConstraints:@[searchBtnLeft, searchBtnWidth, searchBtnHeight, searchBtnCenterY]];
    
    NSLayoutConstraint *changeStyleBtnCenterY = [NSLayoutConstraint constraintWithItem:self.changeStyleButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
    NSLayoutConstraint *changeStyleBtnRight = [NSLayoutConstraint constraintWithItem:self.changeStyleButton attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-10.0];
    NSLayoutConstraint *changeStyleBtnWidth = [NSLayoutConstraint constraintWithItem:self.changeStyleButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:iconWidth];
    NSLayoutConstraint *changeStyleHeight = [NSLayoutConstraint constraintWithItem:self.changeStyleButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:iconWidth];
    [NSLayoutConstraint activateConstraints:@[changeStyleBtnRight, changeStyleBtnWidth, changeStyleHeight, changeStyleBtnCenterY]];
    
    NSLayoutConstraint *sortControlLeft = [NSLayoutConstraint constraintWithItem:self.sortControl attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.searchButton attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:30.0];
    NSLayoutConstraint *sortControlRight = [NSLayoutConstraint constraintWithItem:self.sortControl attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.changeStyleButton attribute:NSLayoutAttributeLeading multiplier:1.0 constant:-30.0];
    NSLayoutConstraint *sortControlTop = [NSLayoutConstraint constraintWithItem:self.sortControl attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:5.0];
    NSLayoutConstraint *sortControlBottom = [NSLayoutConstraint constraintWithItem:self.sortControl attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-5.0];
    [NSLayoutConstraint activateConstraints:@[sortControlLeft, sortControlRight, sortControlTop, sortControlBottom]];
}


- (UIButton *)searchButton {
    if (!_searchButton) {
        _searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
        static UIImage *searchImage = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            searchImage = [[UIImage OSFileBrowserImageNamed:@"sortbar_search"] xy_changeImageColorWithColor:[UIColor whiteColor]];
        });
        [_searchButton setImage:searchImage forState:UIControlStateNormal];
        _searchButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_searchButton addTarget:self action:@selector(searchButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _searchButton;
}

- (UIButton *)changeStyleButton {
    if (!_changeStyleButton) {
        _changeStyleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_changeStyleButton addTarget:self action:@selector(changeStyleButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        _changeStyleButton.translatesAutoresizingMaskIntoConstraints = NO;
        static UIImage *normalImage = nil;
        static UIImage *selectedImage = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
           normalImage = [[UIImage OSFileBrowserImageNamed:@"sortbar_grid_s"] xy_changeImageColorWithColor:[UIColor whiteColor]];
            selectedImage = [[UIImage OSFileBrowserImageNamed:@"sortbar_listview_s"] xy_changeImageColorWithColor:[UIColor whiteColor]];
        });
        [_changeStyleButton setImage:normalImage forState:UIControlStateNormal];
        [_changeStyleButton setImage:selectedImage forState:UIControlStateSelected];
    }
    return _changeStyleButton;
}

- (UISegmentedControl *)sortControl {
    if (!_sortControl) {
        _sortControl = [[UISegmentedControl alloc] initWithItems:@[@"按A-Z的顺序排序", @"最新优先"]];
        _sortControl.selectedSegmentIndex = 0;
        _sortControl.tintColor = [UIColor whiteColor];//[UIColor colorWithRed:0.0/255.0 green:105.0/255.0 blue:210.0/255.0 alpha:1.0];
        _sortControl.translatesAutoresizingMaskIntoConstraints = NO;
        [_sortControl setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor blackColor]} forState:UIControlStateSelected];
        [_sortControl setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
        [_sortControl addTarget:self action:@selector(selectedSortChanged:) forControlEvents:UIControlEventValueChanged];
        _sortControl.selectedSegmentIndex = [OSFileBrowserAppearanceConfigs fileSortType];
    }
    return _sortControl;
}

- (void)updateChangeStyleButton {
    _changeStyleButton.selected = !_changeStyleButton.isSelected;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Notification
////////////////////////////////////////////////////////////////////////
- (void)sortTypeChangeNotification:(NSNotification *)notification {
    if (_sortControl.selectedSegmentIndex != [OSFileBrowserAppearanceConfigs fileSortType]) {
        _sortControl.selectedSegmentIndex = [OSFileBrowserAppearanceConfigs fileSortType];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
////////////////////////////////////////////////////////////////////////
- (void)changeStyleButtonClick:(UIButton *)sender {
    [sender setUserInteractionEnabled:NO];
    OSFileCollectionLayoutStyle style = ![OSFileCollectionViewFlowLayout collectionLayoutStyle];
    [OSFileCollectionViewFlowLayout setCollectionLayoutStyle:style];
    [self updateChangeStyleButton];
    if (self.delegate && [self.delegate respondsToSelector:@selector(fileCollectionHeaderView:reLayoutStyle:)]) {
        [self.delegate fileCollectionHeaderView:self reLayoutStyle:style];
    }
    [sender setUserInteractionEnabled:YES];
}

- (void)searchButtonClick:(UIButton *)btn {
    if (self.delegate && [self.delegate respondsToSelector:@selector(fileCollectionHeaderView:clickedSearchButton:)]) {
        [self.delegate fileCollectionHeaderView:self clickedSearchButton:btn];
    }
}

- (void)selectedSortChanged:(UISegmentedControl *)sortControl {
    [OSFileBrowserAppearanceConfigs setFileSortType:sortControl.selectedSegmentIndex];
    if (self.delegate && [self.delegate respondsToSelector:@selector(fileCollectionHeaderView:didSelectedSortChanged:currentSortType:)]) {
        [self.delegate fileCollectionHeaderView:self didSelectedSortChanged:sortControl currentSortType:sortControl.selectedSegmentIndex];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
