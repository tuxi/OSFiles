//
//  UIImageView+XYExtension.m
//  FileBrowser
//
//  Created by xiaoyuan on 05/08/2014.
//  Copyright © 2014 xiaoyuan. All rights reserved.
//

#import "UIImageView+XYExtension.h"
#import "UIImage+XYImage.h"

@implementation UIImageView (XYExtension)

- (void)xy_imageWithMediaURL:(NSURL *)vidoURL placeholderImage:(UIImage *)placeholderImage completionHandlder:(void (^)(UIImage *image))completionHandlder {
    
    // 取出缓存的图片
    NSString *cachePath = [[self class] getCacheImageFolderPath];
    NSString *imageName = vidoURL.path;
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
    NSString *cachesPath = [self getLibraryPath];
    NSString *path = [cachesPath stringByAppendingPathComponent:@"OSCachehMediaVideoIconFolder"];
    BOOL isDirectory, isExist;
    isExist = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    if (!isExist || !isDirectory) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
    
}
+ (NSString *)getLibraryPath {
    NSArray *userPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    return [userPaths objectAtIndex:0];
}
@end
