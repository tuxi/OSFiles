//
//  UIImageView+XYExtension.h
//  FileDownloader
//
//  Created by Swae on 2017/10/29.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (XYExtension)

/// 根据视频的本地URL，获取第一帧图形，并设置为image，已实现本地缓存
- (void)xy_imageWithMediaURL:(NSURL *)vidoURL placeholderImage:(UIImage *)placeholderImage completionHandlder:(void (^)(UIImage *image))completionHandlder;

@end
