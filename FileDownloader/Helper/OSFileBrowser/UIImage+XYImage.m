//
//  UIImage+XYImage.m
//  FileBrowser
//
//  Created by xiaoyuan on 05/08/2014.
//  Copyright © 2014 xiaoyuan. All rights reserved.
//

#import "UIImage+XYImage.h"

#import <objc/message.h>
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>


@implementation UIImage (XYImage)

+ (UIImage *)OSFileBrowserImageNamed:(NSString *)name {
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"OSFileBrowser.bundle/%@", name]];
    return image;
}

+ (UIImage *)xy_imageWithColor:(UIColor *)color {
    
    // 描述矩形
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    // 开启位图上下文
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
    //    UIGraphicsBeginImageContext(rect.size);
    // 获取位图上下文
    CGContextRef contexRef = UIGraphicsGetCurrentContext();
    // 使用color演示填充上下文
    CGContextSetFillColorWithColor(contexRef, [color CGColor]);
    // 渲染上下文
    CGContextFillRect(contexRef, rect);
    // 从上下文中获取图片
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    // 结束上下文
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)xy_resizingWithImaName:(NSString *)iconName
{
    return [self xy_resizingWithIma: [UIImage imageNamed: iconName]];
}

+ (UIImage *)xy_resizingWithIma:(UIImage *)ima
{
    CGFloat w = ima.size.width * 0.499;
    CGFloat h = ima.size.height * 0.499;
    return [ima resizableImageWithCapInsets: UIEdgeInsetsMake(h, w, h, w)];
}



+ (UIImage *)xy_imageWithOriginalModeImageName:(NSString *)imageName {
    
    UIImage *image = [UIImage imageNamed:imageName];
    
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (UIImage *)xy_originalMode {
    return [self imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}


- (instancetype)xy_circleImage {
    
    // 1.开启图形上下文,并且上下文的尺寸和图片的大小一样
    // 第三个参数:当前点与像素的比例，传0系统会自动适配
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0);
    
    // 2.绘制圆形路径
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
    
    // 3.添加到裁剪
    [path addClip];
    
    // 4.画图
    [self drawAtPoint:CGPointZero];
    
    // 5.从图形上下文获取新的图片
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    // 6.关闭图形上下文
    UIGraphicsEndImageContext();
    
    return image;
    
}

+ (instancetype)xy_circleImageWithImageName:(NSString *)imageName {
    
    return [[self imageNamed:imageName] xy_circleImage];
}

+ (UIImage *)xy_circleImage:(UIImage *)originImage borderColor:(UIColor *)borderColor borderWidth:(CGFloat)borderWidth
{
    // 设置边框的宽度
    CGFloat imageWH = originImage.size.width;
    
    // 设置外圆的尺寸
    CGFloat ovalWH = imageWH + 2*borderWidth;
    
    // 开启图形上下文
    UIGraphicsBeginImageContextWithOptions(originImage.size, NO, 0);
    
    // 画一个椭圆
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, ovalWH, ovalWH)];
    
    [borderColor set];
    [path fill];
    
    // 设置裁剪区域
    UIBezierPath *clipPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(borderWidth, borderWidth, imageWH, imageWH)];
    [clipPath addClip];
    
    // 绘制图片
    [originImage drawAtPoint:CGPointMake(borderWidth, borderWidth)];
    
    // 从上下文中取出图片
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // 关闭图形上下文
    UIGraphicsEndImageContext();
    
    return resultImage;
    
}

+ (UIImage *)blurImage:(UIImage *)image blur:(CGFloat)blur;
{
    // 模糊度越界
    if (blur < 0.f || blur > 1.f) {
        blur = 0.5f;
    }
    int boxSize = (int)(blur * 40);
    boxSize = boxSize - (boxSize % 2) + 1;
    CGImageRef img = image.CGImage;
    vImage_Buffer inBuffer, outBuffer;
    vImage_Error error;
    void *pixelBuffer;
    //从CGImage中获取数据
    CGDataProviderRef inProvider = CGImageGetDataProvider(img);
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);
    //设置从CGImage获取对象的属性
    inBuffer.width = CGImageGetWidth(img);
    inBuffer.height = CGImageGetHeight(img);
    inBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    inBuffer.data = (void*)CFDataGetBytePtr(inBitmapData);
    
    pixelBuffer = malloc(CGImageGetBytesPerRow(img) *
                         CGImageGetHeight(img));
    
    if(pixelBuffer == NULL)
        NSLog(@"No pixelbuffer");
    
    outBuffer.data = pixelBuffer;
    outBuffer.width = CGImageGetWidth(img);
    outBuffer.height = CGImageGetHeight(img);
    outBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    
    if (error) {
        NSLog(@"error from convolution %ld", error);
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(
                                             outBuffer.data,
                                             outBuffer.width,
                                             outBuffer.height,
                                             8,
                                             outBuffer.rowBytes,
                                             colorSpace,
                                             kCGImageAlphaNoneSkipLast);
    CGImageRef imageRef = CGBitmapContextCreateImage (ctx);
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef];
    
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    
    free(pixelBuffer);
    CFRelease(inBitmapData);
    
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(imageRef);
    
    return returnImage;
}

+ (UIImage *)xy_imageWithMediaURL:(NSURL *)vidoURL {
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                     forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    // 初始化媒体文件
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:vidoURL options:opts];
    // 根据asset构造一张图
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];
    // 设定缩略图的方向
    // 如果不设定，可能会在视频旋转90/180/270°时，获取到的缩略图是被旋转过的，而不是正向的（自己的理解）
    generator.appliesPreferredTrackTransform = YES;
    // 设置图片的最大size(分辨率)
    generator.maximumSize = CGSizeMake(600, 450);
    // 初始化error
    NSError *error = nil;
    // 根据时间，获得第N帧的图片
    CMTime time = CMTimeMake(0, 10000); // 获取0帧处的视频截图
    // CMTimeMake(a, b)可以理解为获得第a/b秒的frame
    CGImageRef img = [generator copyCGImageAtTime:time actualTime:NULL error:&error];
    // 构造图片
    UIImage *videoScreen;
    if ([self isRetina]){
        videoScreen = [[UIImage alloc] initWithCGImage:img scale:2.0 orientation:UIImageOrientationUp];
    } else {
        videoScreen = [[UIImage alloc] initWithCGImage:img];
    }
    
    CGImageRelease(img);
    
    return videoScreen;
}

/// 更改图片的颜色
- (UIImage *)xy_changeImageColorWithColor:(UIColor *)color {
    
    UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, self.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    CGContextClipToMask(context, rect, self.CGImage);
    [color setFill];
    CGContextFillRect(context, rect);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (UIImage *)xy_musicImageWithMusicURL:(NSURL *)url {
    NSData *data = nil;
    // 初始化媒体文件
    AVURLAsset *mp3Asset = [AVURLAsset URLAssetWithURL:url options:nil];
    // 读取文件中的数据
    for (NSString *format in [mp3Asset availableMetadataFormats]) {
        for (AVMetadataItem *metadataItem in [mp3Asset metadataForFormat:format]) {
            //artwork这个key对应的value里面存的就是封面缩略图，其它key可以取出其它摘要信息，例如title - 标题
            if ([metadataItem.commonKey isEqualToString:@"artwork"]) {
                data = [(NSDictionary*)metadataItem.value objectForKey:@"data"];
                break;
            }
        }
    }
    if (!data) {
        // 如果音乐没有图片，就返回默认图片
        return [UIImage imageNamed:@"default"];
    }
    return [UIImage imageWithData:data];
}



// 返回渐变的image
+ (UIImage*)xy_gradientImageFromColors:(NSArray*)colors ByGradientType:(GradientType)gradientType inSize:(CGSize)size {
    NSMutableArray *ar = [NSMutableArray array];
    for(UIColor *c in colors) {
        [ar addObject:(id)c.CGColor];
    }
    UIGraphicsBeginImageContextWithOptions(size, YES, 1);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGColorSpaceRef colorSpace = CGColorGetColorSpace([[colors lastObject] CGColor]);
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef)ar, NULL);
    CGPoint start;
    CGPoint end;
    switch (gradientType) {
            //上下渐变
        case 0:
            start = CGPointMake(0.0, 0.0);
            end = CGPointMake(0.0, size.height);
            break;
        case 1:
            //左右渐变
            start = CGPointMake(0.0, 0.0);
            end = CGPointMake(size.width, 0.0);
            break;
        case 2:
            //对角两侧渐变
            start = CGPointMake(0.0, 0.0);
            end = CGPointMake(size.width, size.height);
            break;
        case 3:
            //对角两侧渐变
            start = CGPointMake(size.width, 0.0);
            end = CGPointMake(0.0, size.height);
            break;
        case 4:
            //线性渐变
            start = CGPointMake(size.width/2, size.height/2);
            end = CGPointMake(size.width/2, size.height/2);
            break;
        default:
            break;
    }
    CGContextDrawLinearGradient(context, gradient, start, end, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    
    if (gradientType == 4) {
        CGContextDrawRadialGradient(context, gradient, start, 10, end, size.width/3, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
        
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    CGGradientRelease(gradient);
    CGContextRestoreGState(context);
    CGColorSpaceRelease(colorSpace);
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)filterWith:(UIImage *)image andRadius:(CGFloat)radius {
    
    CIImage *inputImage = [[CIImage alloc] initWithCGImage:image.CGImage];
    
    CIFilter *affineClampFilter = [CIFilter filterWithName:@"CIAffineClamp"];
    CGAffineTransform xform = CGAffineTransformMakeScale(1.0, 1.0);
    [affineClampFilter setValue:inputImage forKey:kCIInputImageKey];
    [affineClampFilter setValue:[NSValue valueWithBytes:&xform
                                               objCType:@encode(CGAffineTransform)]
                         forKey:@"inputTransform"];
    
    CIImage *extendedImage = [affineClampFilter valueForKey:kCIOutputImageKey];
    
    CIFilter *blurFilter =
    [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setValue:extendedImage forKey:kCIInputImageKey];
    [blurFilter setValue:@(radius) forKey:@"inputRadius"];
    
    CIImage *result = [blurFilter valueForKey:kCIOutputImageKey];
    
    CIContext *ciContext = [CIContext contextWithOptions:nil];
    
    CGImageRef cgImage = [ciContext createCGImage:result fromRect:inputImage.extent];
    
    UIImage *uiImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    return uiImage;
}

+ (UIImage *)xy_imageFlippedForRTLLayoutDirectionNamed:(NSString *)name {
    if (floor(NSFoundationVersionNumber) >= NSFoundationVersionNumber_iOS_9_0) {
        return [[UIImage imageNamed:name] imageFlippedForRightToLeftLayoutDirection];
    }
    return [UIImage imageNamed:name];
}

- (UIImage *)stringImageTinted:(NSString *)string font:(UIFont *)font inset:(CGFloat)inset
{
    CGSize baseSize = [string sizeWithAttributes:@{NSFontAttributeName: font}];
    CGSize adjustSize = CGSizeMake(baseSize.width + inset * 2, baseSize.height + inset * 2);
    
    // 开启图像上下文
    UIGraphicsBeginImageContextWithOptions(adjustSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 绘制白色背景
    CGRect bounds = (CGRect){.size = adjustSize};
    // 设置绘图颜色
    [[UIColor whiteColor] set];
    CGContextAddRect(context, bounds);
    CGContextFillPath(context);
    
    // 绘制随机色, 覆盖白色背景
    [[UIColor colorWithRed:((rand() % 255) / 255.0f)
                     green:((rand() % 255) / 255.0f)
                      blue:((rand() % 255) / 255.0f)
                     alpha:0.5f] set];
    CGContextAddRect(context, bounds);
    CGContextFillPath(context);
    
    // 绘制黑色线框
    [[UIColor blackColor] set];
    CGContextAddRect(context, bounds);
    CGContextSetLineWidth(context, inset);
    CGContextStrokePath(context);
    
    // 绘制文字
    CGRect insetBounds = CGRectInset(bounds, inset, inset);
    // 段落格式
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;   // 断行模式
    paragraphStyle.alignment = NSTextAlignmentCenter;           // 居中显示
    [string drawInRect:insetBounds withAttributes:@{
                                                    NSFontAttributeName: font,
                                                    NSParagraphStyleAttributeName: paragraphStyle,
                                                    NSForegroundColorAttributeName: [UIColor blackColor]
                                                    }];
    // 从图像上下文获得图片
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    // 关闭图像上下文
    UIGraphicsEndImageContext();
    return image;
    
}
#pragma mark - private
+ (BOOL)isRetina {
    return ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
            ([UIScreen mainScreen].scale > 1.0));
}


@end


