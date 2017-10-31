//
//  UIImageView+XYExtension.m
//  FileDownloader
//
//  Created by Swae on 2017/10/29.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "UIImageView+XYExtension.h"
#import "OSFileDownloaderConfiguration.h"

@implementation UIImageView (XYExtension)

- (void)xy_imageWithMediaURL:(NSURL *)vidoURL placeholderImage:(UIImage *)placeholderImage completionHandlder:(void (^)(UIImage *image))completionHandlder {
    
    // 取出缓存的图片
    NSString *cachePath = [[self class] getCacheImageFolderPath];
    NSString *imageName = [vidoURL.path MD5Hash];
    NSString *fullPath = [cachePath stringByAppendingPathComponent:imageName];
    UIImage *image = [UIImage imageWithContentsOfFile:fullPath];
    if (image) {
        self.image = image;
        if (completionHandlder) {
            completionHandlder(image);
        }
        return;
    }
    
    if (placeholderImage) {
        if (completionHandlder) {
            completionHandlder(placeholderImage);
        }
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        UIImage *image = [UIImage xy_imageWithMediaURL:vidoURL];
        if (image) {
            NSData *imagedata = UIImagePNGRepresentation(image);
            [imagedata writeToFile:fullPath atomically:YES];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.image = image;
            });
            
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.image = image;
            });
        }
        if (completionHandlder) {
            completionHandlder(image);
        }
    });
    
}

+ (NSString *)getCacheImageFolderPath {
    NSString *cachesPath = [OSFileDownloaderConfiguration getLibraryPath];
    NSString *path = [cachesPath stringByAppendingPathComponent:@"OSCachehMediaVideoIconFolder"];
    BOOL isDirectory, isExist;
    isExist = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    if (!isExist || !isDirectory) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
    
}


@end
