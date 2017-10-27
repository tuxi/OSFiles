//
//  UIScrollView+NoDataExtend.h
//  NODataPlaceholderView
//
//  Created by Ossey on 2017/5/29.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NoDataPlaceholderDelegate;

@interface UIScrollView (NoDataExtend)

@property (nonatomic, weak, nullable) id<NoDataPlaceholderDelegate> noDataPlaceholderDelegate;

/// use custom view
@property (nonatomic, copy) UIView * _Nullable (^customNoDataView)(void);

// setup subviews
@property (nonatomic, copy) void  (^ _Nullable noDataTextLabelBlock)(UILabel *textLabel);
@property (nonatomic, copy) void  (^ _Nullable noDataDetailTextLabelBlock)(UILabel *detailTextLabel);
@property (nonatomic, copy) void  (^ _Nullable noDataImageViewBlock)(UIImageView *imageView);
@property (nonatomic, copy) void  (^ _Nullable noDataReloadButtonBlock)(UIButton *reloadButton);

/// titleLabel 的间距
@property (nonatomic, assign) UIEdgeInsets noDataTextEdgeInsets;
/// imageView 的间距
@property (nonatomic, assign) UIEdgeInsets noDataImageEdgeInsets;
/// detaileLable 的间距
@property (nonatomic, assign) UIEdgeInsets noDataDetailEdgeInsets;
/// reloadButton 的间距
@property (nonatomic, assign) UIEdgeInsets noDataButtonEdgeInsets;

/// noDataPlaceholderView 的背景颜色
@property (nonatomic, strong) UIColor *noDataViewBackgroundColor;
/// noDataPlaceholderView中contentView的背景颜色
@property (nonatomic, strong) UIColor *noDataViewContentBackgroundColor;
@property (nonatomic, assign) BOOL xy_loading;

/// 刷新NoDataView, 当执行tableView的readData、endUpdates或者CollectionView的readData时会调用此方法
- (void)xy_reloadNoData;

@end

@protocol NoDataPlaceholderDelegate <NSObject>

@optional

/// 是否应该淡入淡出，默认为YES
- (BOOL)noDataPlaceholderShouldFadeInOnDisplay:(UIScrollView *)scrollView;

/// 是否应显示NoDataPlaceholderView, 默认YES
/// @return 如果当前无数据则应显示NoDataPlaceholderView
- (BOOL)noDataPlaceholderShouldDisplay:(UIScrollView *)scrollView;

/// 当前所在页面的数据源itemCount>0时，是否应该实现NoDataPlaceholder，默认是不显示的
/// @return 如果需要强制显示NoDataPlaceholder，return YES即可
- (BOOL)noDataPlaceholderShouldBeForcedToDisplay:(UIScrollView *)scrollView;

/// 当noDataPlaceholder即将显示的回调
- (void)noDataPlaceholderWillAppear:(UIScrollView *)scrollView;

/// 当noDataPlaceholder完全显示的回调
- (void)noDataPlaceholderDidAppear:(UIScrollView *)scrollView;

/// 当noDataPlaceholder即将消失的回调
- (void)noDataPlaceholderWillDisappear:(UIScrollView *)scrollView;

/// 当noDataPlaceholder完全消失的回调
- (void)noDataPlaceholderDidDisappear:(UIScrollView *)scrollView;

/// noDataPlaceholder是否可以响应事件，默认YES
- (BOOL)noDataPlaceholderShouldAllowResponseEvent:(UIScrollView *)scrollView;

/// noDataPlaceholder是否可以滚动，默认YES
- (BOOL)noDataPlaceholderShouldAllowScroll:(UIScrollView *)scrollView;

- (void)noDataPlaceholder:(UIScrollView *)scrollView didTapOnContentView:(UITapGestureRecognizer *)tap;

- (void)noDataPlaceholder:(UIScrollView *)scrollView didClickReloadButton:(UIButton *)button;

/// NoDataPlaceholderView各子控件之间垂直的间距，默认为11
- (CGFloat)contentSubviewsGlobalVerticalSpaceFoNoDataPlaceholder:(UIScrollView *)scrollView;

/// NoDataPlaceholderView 的 contentView左右距离父控件的间距值
- (CGFloat)contentViewHorizontalSpaceFoNoDataPlaceholder:(UIScrollView *)scrollView;

/// NoDataPlaceholderView 顶部 距离 父控件scrollView 顶部 的偏移量
/// 默认为0，与所在scrollView的中心点显示
- (CGFloat)contentOffsetYForNoDataPlaceholder:(UIScrollView *)scrollView;

/// imageView的size, 有的时候图片本身太大，导致imageView的尺寸并不是我们想要的，可以通过此方法设置, 当为CGSizeZero时不设置,默认为CGSizeZero
- (CGSize)imageViewSizeForNoDataPlaceholder:(UIScrollView *)scrollView;
@end


NS_ASSUME_NONNULL_END

