//
//  UIImage+XYImage.h
//  FileBrowser
//
//  Created by xiaoyuan on 05/08/2014.
//  Copyright © 2014 xiaoyuan. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, GradientType) {
    GradientTypeUpToDown = 0,  /*** 上下渐变 **/
    GradientTypeLeftToRight,   /*** 左右渐变 **/
    GradientTypeDiagonalOnBothSides, /*** 对角两侧渐变 **/
    GradientTypeDiagonalOnBothSidesOfTheGradient, /*** 对角两侧渐变 **/
    GradientTypeLinear /** 线性渐变 **/
};

@interface UIImage (XYImage)

/// 获取OSFileBrowser.bundle中的图片
+ (UIImage *)OSFileBrowserImageNamed:(NSString *)name;

/// 根据一个图片的名字快速生成没有渲染的图片
/// @param   imageName  原始图片名称
/// @return  没有渲染的图片
+ (instancetype)xy_imageWithOriginalModeImageName:(NSString *)imageName;
- (UIImage *)xy_originalMode;

/// 处理图片为圆形图片
/// @return  圆形图片
- (instancetype)xy_circleImage;
+ (instancetype)xy_circleImageWithImageName:(NSString *)imageName;

/// 根据颜色生成一张尺寸为1*1的相同颜色图片
/// @param   color  要生成图片的颜色
/// @return  相同颜色的图片
+ (UIImage *)xy_imageWithColor:(UIColor *)color;

+ (UIImage *)xy_resizingWithImaName:(NSString *)iconName;
+ (UIImage *)xy_resizingWithIma:(UIImage *)ima;

/// @param   originImage  原始图片
/// @param   borderColor  边框颜色
/// @param   borderWidth  边框宽度
/// @return  带边框的圆形图片
+ (UIImage *)xy_circleImage:(UIImage *)originImage borderColor:(UIColor *)borderColor borderWidth:(CGFloat)borderWidth;

/// 异步通过视频的URL，获得视频缩略图
///  @param vidoURL 视频URL
///  @return image 首帧缩略图
+ (UIImage *)xy_imageWithMediaURL:(NSURL *)vidoURL;

/// 更改图片的颜色
- (UIImage *)xy_changeImageColorWithColor:(UIColor *)color;

/// 返回渐变的image
+ (UIImage*)xy_gradientImageFromColors:(NSArray*)colors ByGradientType:(GradientType)gradientType inSize:(CGSize)size;

/// 通过音乐地址，读取音乐数据，获得图片
/// @param url 音乐地址
/// @return音乐图片
+ (UIImage *)xy_musicImageWithMusicURL:(NSURL *)url;

/// 图片滤镜处理
/// @param image  UIImage类型
/// @param radius 虚化参数
/// @return 虚化后的UIImage
+ (UIImage *)filterWith:(UIImage *)image andRadius:(CGFloat)radius;

/// 生成一张高斯模糊的图片
/// @param image 原图
/// @param blur  模糊程度 (0~1)
/// @return 高斯模糊图片
+ (UIImage *)blurImage:(UIImage *)image blur:(CGFloat)blur;

+ (UIImage *)xy_imageFlippedForRTLLayoutDirectionNamed:(NSString *)name;

/// 根据文字, 字体, 内边距生成图片
- (UIImage *)stringImageTinted:(NSString *)string font:(UIFont *)font inset:(CGFloat)inset;
@end


