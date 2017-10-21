//
//  UIScrollView+NoDataPlaceholder.h
//  NODataPlaceholderView
//
//  Created by Ossey on 2017/5/29.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^NoDataPlaceholderContentViewAttribute)(UIButton * const reloadBtn, UILabel * const titleLabel, UILabel * const detailLabel, UIImageView * const imageView);

@protocol NoDataPlaceholderDelegate, NoDataPlaceholderDataSource;

@interface UIScrollView (NoDataPlaceholder)

@property (nonatomic, weak, nullable) id<NoDataPlaceholderDataSource> noDataPlaceholderDataSource;
@property (nonatomic, weak, nullable) id<NoDataPlaceholderDelegate> noDataPlaceholderDelegate;
@property (nonatomic, assign, readonly, getter=isNoDatasetVisible) BOOL noDatasetVisible;

@property (nonatomic, assign, getter=isLoading) BOOL loading;

/// 刷新NoDataPlaceholder, 当执行reloadData时也会执行该方法内部的实现
- (void)reloadNoDataView;

/// 通过此block可以对contentView的四个子控件设置，若使用了此属性，则与其相关的数据源方法不再调用
- (void)setNoDataPlaceholderContentViewAttribute:(NoDataPlaceholderContentViewAttribute)noDataPlaceholderContentViewAttribute;

@end

@protocol NoDataPlaceholderDelegate <NSObject>

@optional

/// 是否应该淡入淡出，默认为YES
- (BOOL)noDataPlaceholderShouldFadeInOnDisplay:(UIScrollView *)scrollView;

/// 是否应显示NoDataPlaceholderView, 默认YES
/// @param scrollView UIScrollView及其子类对象通知代理
/// @return 如果当前无数据则应显示NoDataPlaceholderView
- (BOOL)noDataPlaceholderShouldDisplay:(UIScrollView *)scrollView;

/// 当前所在页面的数据源itemCount>0时，是否应该实现NoDataPlaceholder，默认是不显示的
/// @param scrollView UIScrollView及其子类对象通知代理
/// @return 如果需要强制显示NoDataPlaceholder，返回YES即可
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

/// noDataPlaceholder是否可以滚动，默认NO
- (BOOL)noDataPlaceholderShouldAllowScroll:(UIScrollView *)scrollView;

/// imageview是否可以有动画，默认为NO
- (BOOL)noDataPlaceholderShouldAnimateImageView:(UIScrollView *)scrollView;


- (void)noDataPlaceholder:(UIScrollView *)scrollView didTapOnContentView:(UITapGestureRecognizer *)tap;

- (void)noDataPlaceholder:(UIScrollView *)scrollView didClickReloadButton:(UIButton *)button;

@end

@protocol NoDataPlaceholderDataSource <NSObject>

@optional

/// 当需要显示customView时，默认的NoDataPlaceholder则为会被清空
/// @param scrollview UIScrollView 或其子类对象
/// @return 自定义视图
- (UIView *)customViewForNoDataPlaceholder:(UIScrollView *)scrollview;

/// NoDataPlaceholder需要显示的标题富文本
/// @return NSAttributedString富文本
- (NSAttributedString *)titleAttributedStringForNoDataPlaceholder:(UIScrollView *)scrollView;

/// NoDataPlaceholder需要显示的详情富文本
/// @return NSAttributedString富文本
- (NSAttributedString *)detailAttributedStringForNoDataPlaceholder:(UIScrollView *)scrollView;

/// NoDataPlaceholder的图片
///@return UIImage
- (UIImage *)imageForNoDataPlaceholder:(UIScrollView *)scrollView;

/// 图片的动画，默认为nil
/// @return CAAnimation
- (CAAnimation *)imageAnimationForNoDataPlaceholder:(UIScrollView *)scrollView;

/// 图片的tintColor , 默认无
/// @return UIColor
- (UIColor *)imageTintColorForNoDataPlaceholder:(UIScrollView *)scrollView;

/// 指定reloadButton对应state的富文本
/// @return NSAttributedString类型
- (NSAttributedString *)reloadbuttonTitleAttributedStringForNoDataPlaceholder:(UIScrollView *)scrollView forState:(UIControlState)state;

/// 指定reloadButton对应state的image
- (UIImage *)reloadButtonImageForNoDataPlaceholder:(UIScrollView *)scrollView forState:(UIControlState)state;

/// reloadButton背景image
- (UIImage *)reloadButtonBackgroundImageForNoDataPlaceholder:(UIScrollView *)scrollView forState:(UIControlState)state;

/// NoDataPlaceholder的背景颜色
- (UIColor *)backgroundColorForNoDataPlaceholder:(UIScrollView *)scrollView;

/// reloadButton背景颜色
- (UIColor *)reloadButtonBackgroundColorForNoDataPlaceholder:(UIScrollView *)scrollView;

/// NoDataPlaceholderView各子控件之间垂直的间距，默认为11
- (CGFloat)contentSubviewsVerticalSpaceFoNoDataPlaceholder:(UIScrollView *)scrollView;

/// NoDataPlaceholderView contenView 中心点y 轴 距离 父控件scrollView 中心点y 的偏移量
/// 默认为0，与所在scrollView的中心点显示
- (CGFloat)contentOffsetYForNoDataPlaceholder:(UIScrollView *)scrollView;

@end

NS_ASSUME_NONNULL_END
