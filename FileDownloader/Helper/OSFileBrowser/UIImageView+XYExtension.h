//
//  UIImageView+XYExtension.h
//  FileBrowser
//
//  Created by xiaoyuan on 05/08/2014.
//  Copyright © 2014 xiaoyuan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (XYExtension)

/// 根据视频的本地URL，获取第一帧图形，并设置为image，已实现本地缓存
- (void)xy_imageWithMediaURL:(NSURL *)vidoURL placeholderImage:(UIImage *)placeholderImage completionHandlder:(void (^)(UIImage *image))completionHandlder;


@end
