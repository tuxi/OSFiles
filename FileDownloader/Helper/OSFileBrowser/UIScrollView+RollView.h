//
//  UIView+XYRollView.h
//  XYRrearrangeCell
//  
//  Created by alpface on 16/11/7.
//  Copyright © 2016年 alpface. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, XYRollViewScrollDirection) {
    XYRollViewScrollDirectionNotKnow,
    XYRollViewScrollDirectionVertical,
    XYRollViewScrollDirectionHorizontal
};

@protocol XYRollViewScrollDelegate <NSObject>

@required
/// 拖拽cell时是否需要交换数据
- (BOOL)rollView:(UIScrollView *)scrollView shouldNeedExchangeDataSourceFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;

@optional
- (void)rollView:(UIScrollView *)scrollView didRollingWithBeginIndexPath:(NSIndexPath *)beginRollIndexPath lastRollIndexPath:(NSIndexPath *)lastRollIndexPath fingerIndexPath:(NSIndexPath *)fingerIndexPath;

/// 当将一个cell移动到另一个cell上，并一直停留时调用
- (void)rollView:(UIScrollView *)scrollView didRollingWithBeginIndexPath:(NSIndexPath *)beginRollIndexPath inSameIndexPath:(NSIndexPath *)fingerIndexPath waitingDuration:(NSTimeInterval)waitingDuration;

- (void)rollView:(UIScrollView *)scrollView stopRollingWithBeginIndexPath:(NSIndexPath *)beginRollIndexPath lastRollIndexPath:(NSIndexPath *)lastRollIndexPath fingerIndexPath:(NSIndexPath *)fingerIndexPath waitingDuration:(NSTimeInterval)waitingDuration;

/// 返回外界的数据给当前类 作用:在移动cell数据发生改变时，拿到外界的数据重新排列数据
- (NSArray *)rollViewFromOriginalDataSource:(UIScrollView *)scrollView;
/// 回调重新排列的数据给外界, 不需要调用reloadData
- (void)rollView:(UIScrollView *)scrollView didRollingWithNewDataSource:(NSArray *)newDataSource;

@end

@interface UIScrollView (RollView)

/** cell在滚动时的阴影颜色,默认为黑色 */
@property (nonatomic, strong) UIColor * __nullable rollingColor;

/** cell在滚动时的阴影的不透明度,默认为0.3 */
@property (nonatomic, assign) CGFloat rollIngShadowOpacity;

/** cell拖拽到屏幕边缘时，其他cell的滚动速度，数值越大滚动越快，默认为5.0,最大为15 */
@property (nonatomic, assign) CGFloat autoRollCellSpeed;

/** cell拖拽时允许拖拽的方向 */
@property (nonatomic, assign, readonly) XYRollViewScrollDirection rollDirection;

@property (nonatomic, weak) id<XYRollViewScrollDelegate> rollingDelegate;

@end

NS_ASSUME_NONNULL_END
