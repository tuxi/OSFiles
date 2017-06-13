//
//  XYImageBrowerView.h
//  image-viewer
//
//  Created by mofeini on 17/1/5.
//  Copyright © 2017年 com.test.demo. All rights reserved.
//

#import <UIKit/UIKit.h>


@class XYImageBrowerView, XYImagePageLabel, XYImageView, XYImageProgressView;

@protocol XYImageBrowerViewDelegate <NSObject>

@required


/**
 *  获取对应索引的视图
 *
 * @param   imageBrowerView  图片浏览器
 * @param   index          索引
 * @return  图片大小
 * @return  对应索引的视图
 */
- (UIView *)imageBrowerView:(XYImageBrowerView *)imageBrowerView viewForIndex:(NSInteger)index;


/**
 *  获取所有要的高质量图片地址字符串
 *
 * @return  图片的 url 字符串数组
 * 注意: 当执行了获取图片url数组的方法，就不再执行获取单张图片url的方法
 */
- (NSArray<NSString *> *)imageBrowerViewWithOriginalImageUrlStrArray:(XYImageBrowerView *)imageBrowerView;


@optional

/**
 *  获取对应索引的图片大小
 *
 * @param   imageBrowerView  图片浏览器
 * @return  图片大小
 */
- (CGSize)imageBrowerView:(XYImageBrowerView *)imageBrowerView imageSizeForIndex:(NSInteger)index;



/**
 *  获取对应索引默认图片，可以是占位图片，可以是缩略图
 *
 * @param   imageBrowerView  图片浏览器
 * @param   index          索引
 * @return  图片
 */
- (UIImage *)imageBrowerView:(XYImageBrowerView *)imageBrowerView defaultImageForIndex:(NSInteger)index;

/**
 获取所有默认图片，可以是占位图片，可以是缩略图
 
 @return 图片名 字符串数组
 
 注意: 当执行了获取图片数组的方法，就不再执行获取单张图片的方法
 */

/**
 *  获取要显示的默认图片数组，可以是占位图片，可以是缩略图
 *
 * @param   imageBrowerView  图片浏览器
 * @return  图片名称 字符串数组
 */
- (NSArray<NSString *> *)imageBrowerViewWithImageNameArray:(XYImageBrowerView *)imageBrowerView;


/**
 *  获取对应索引的高质量图片地址字符串
 *
 * @param   imageBrowerView  图片浏览器
 * @param   index          索引
 * @return  图片的 url 字符串
 */
- (NSString *)imageBrowerView:(XYImageBrowerView *)imageBrowerView highQualityUrlStringForIndex:(NSInteger)index;

/**
 *  获取对应索引的图片上的文本
 *
 * @param   imageBrowerView  图片浏览器
 * @param   index          索引
 * @return  图片显示的 字符串, 默认为当前页码/总页码
 */
- (NSString *)imageBrowerView:(XYImageBrowerView *)imageBrowerView pageTextAtIndex:(NSInteger)index;

@end



@interface XYImageBrowerView : UIView


@property (nonatomic, weak) id<XYImageBrowerViewDelegate> delegate;

/// 图片之间的间距，默认20
@property (nonatomic, assign) CGFloat imagesSpacing;

/// 每个页面显示文本的控件
@property (nonatomic, weak, readonly) XYImagePageLabel *pageTextLabel;


/// 长按图片要执行的事件，将长按图片索引回调
@property (nonatomic, copy) void(^longPressBlock)(NSInteger);


/// 动画执行的时间, 默认为0.25秒
@property (nonatomic, assign) CGFloat duration;


/// 关闭图片浏览器时，动画消失后的回调
@property (nonatomic, copy) void (^dismissCallBack)();

/**
 *  显示图片浏览器
 *
 * @param   fromView  用户点击的视图，图片这个视图开始做动画，并打开图片浏览器
 * @param   picturesCount  图片的数量
 * @param   currentPictureIndex  当前点击图片的索引值
 */
- (void)showFromView:(UIView *)fromView picturesCount:(NSInteger)picturesCount currentPictureIndex:(NSInteger)currentPictureIndex;

/// 让图片浏览器消失
- (void)dismiss;

@end

@interface XYImagePageLabel : UILabel


@end


@protocol XYImageViewDelegate <NSObject>

- (void)imageViewTouch:(XYImageView *)imageView;

- (void)imageView:(XYImageView *)imageView scale:(CGFloat)scale;

- (void)imageViewDidScrollTopOrBottom:(XYImageView *)imageView;

- (void)imageViewDidEndDragging:(XYImageView *)imageView;

@end



@interface XYImageView : UIScrollView

/// 当前视图所在的索引
@property (nonatomic, assign) NSInteger index;
/// 图片的大小
@property (nonatomic, assign) CGSize pictureSize;
/// 显示的默认图片
@property (nonatomic, strong) UIImage *placeholderImage;
/// 图片的地址 URL
@property (nonatomic, strong) NSString *urlString;
/// 当前显示图片的控件
@property (nonatomic, strong, readonly) UIImageView *imageView;
/// 代理
@property (nonatomic, weak) id<XYImageViewDelegate> imageViewDelegate;


/**
 *  动画显示
 *
 * @param   rect            从哪个位置开始做动画
 * @param   animationBlock  附带的动画信息
 * @param   completionBlock 结束的回调
 */
- (void)animationShowWithFromRect:(CGRect)rect duration:(CGFloat)duration  animationBlock:(void(^)())animationBlock completionBlock:(void(^)())completionBlock;


/**
 *  动画消失
 *
 * @param   rect            回到哪个位置
 * @param   animationBlock  附带的动画信息
 * @param   completionBlock 结束的回调
 */
- (void)animationDismissWithToRect:(CGRect)rect duration:(CGFloat)duration  animationBlock:(void(^)())animationBlock completionBlock:(void(^)())completionBlock;


@end

@interface XYImageProgressView : UIView

@property (nonatomic, assign) CGFloat progress;

- (void)showError;

@end
