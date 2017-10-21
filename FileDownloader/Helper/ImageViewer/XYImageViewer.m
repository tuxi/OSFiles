//
//  XYImageViewer.m
//  image-viewer
//
//  Created by mofeini on 17/1/5.
//  Copyright © 2017年 com.test.demo. All rights reserved.
//

#import "XYImageViewer.h"
#import "XYImageBrowerView.h"

@interface XYImageViewer () <XYImageBrowerViewDelegate>

/// 图片浏览器视图
@property (nonatomic, strong) XYImageBrowerView *browerView;
/// 图片的尺寸数组，当加载本地图片时可用，网络请求不需要
@property (nonatomic, strong) NSArray* imageSizes;
/// 获取点击的当前视图
@property (nonatomic, strong) UIView *fromView;
/// 关闭图片浏览器时点击对应索引的视图, 回调给外界当前点击的索引，外界从tableView或者collectionView中找到对应的cell给我即可
@property (nonatomic, strong) UIView *(^endViewBlock)(NSIndexPath *);
/// 获取对应索引默认图片，可以是占位图片，可以是缩略图
@property (nonatomic, strong) UIImage *image;
/// 需要展示的图片数组，当传入urlStrList后就不用传这个属性了
@property (nonatomic, strong) NSArray<NSString *> *images;
/// 图片的url 字符串数组
@property (nonatomic, strong) NSArray<NSString *> *urlStrList;
/// 当外界调用了prepareImageURLList时为YES，调用prepareImages时为NO
@property (nonatomic, assign, getter=isRequestFromNetwork) BOOL requestFromNetwork;
@property (nonatomic, strong) NSArray<NSString *> *pageTextList;

@end

@implementation XYImageViewer

#pragma mark - 公开方法

- (XYImageBrowerView *)showWithImageURLList:(NSArray<NSString *> *)URLList
                               currentIndex:(NSInteger)currentIndex
                                   fromView:(UIView *)fromView
                                    endView:(UIView *(^)(NSIndexPath *indexPath))endViewBlock {
    
    XYImageViewer *viewr = [XYImageViewer prepareImageURLList:URLList pageTextList:nil endView:endViewBlock];
    return [viewr show:fromView currentIndex:currentIndex];
}

- (__kindof UIView *)show:(UIView *)fromView currentIndex:(NSInteger)currentImgIndex {
    
    NSInteger imgCount = 0;
    if (self.isRequestFromNetwork == YES) {
        /// 从服务器请求
        imgCount = self.urlStrList.count;
    } else {
        /// 加载本地图片
        imgCount = self.images.count;
    }
    [self.browerView showFromView:fromView picturesCount:imgCount currentPictureIndex:currentImgIndex];
    
    return self.browerView;
}


+ (instancetype)prepareImageURLList:(NSArray<NSString *> *)URLList
                       pageTextList:(NSArray<NSString *> *)pageTextList
                            endView:(UIView *(^)(NSIndexPath *indexPath))endViewBlock {
    
    XYImageViewer *imageViewr = [XYImageViewer new];
    
    imageViewr.urlStrList = URLList;
    imageViewr.endViewBlock = endViewBlock;
    imageViewr.requestFromNetwork = YES;
    imageViewr.pageTextList = pageTextList;
    
    return imageViewr;
}


+ (instancetype)prepareImages:(NSArray<NSString*> *)images
                 pageTextList:(NSArray<NSString *> *)pageTextList
                      endView:(UIView *(^)(NSIndexPath *indexPath))endViewBlock {
    
    XYImageViewer *imageViewr = [XYImageViewer new];
    imageViewr.images = images;
    imageViewr.endViewBlock = endViewBlock;
    imageViewr.requestFromNetwork = NO;
    imageViewr.pageTextList = pageTextList;
    
    NSMutableArray *tempArrM = [NSMutableArray arrayWithCapacity:1];
    for (NSString *imageName in images) {
        UIImage *image = nil;
        if ([imageName isKindOfClass:[NSString class]]) {
            image = [UIImage imageNamed:imageName];
            if (!image) {
                image = [UIImage imageWithContentsOfFile:imageName];
            }
        } else if ([imageName isKindOfClass:[NSURL class]]) {
            NSData *data = [NSData dataWithContentsOfURL:(NSURL *)imageName];
            image = [UIImage imageWithData:data];
        }
      
        [tempArrM addObject:[NSValue valueWithCGSize:image.size]];
    }
    
    imageViewr.imageSizes = [tempArrM mutableCopy];
    tempArrM = nil;
    return imageViewr;
}


#pragma mark - XYImageBrowerViewDelegate

- (UIView *)imageBrowerView:(XYImageBrowerView *)imageBrowerView viewForIndex:(NSInteger)index {
    
    return self.endViewBlock([NSIndexPath indexPathForRow:index inSection:0]);
}

- (NSArray<NSString *> *)imageBrowerViewWithOriginalImageUrlStrArray:(XYImageBrowerView *)imageBrowerView {
    return self.urlStrList;
}

- (NSArray<NSString *> *)imageBrowerViewWithImageNameArray:(XYImageBrowerView *)imageBrowerView {
    
    return self.images;
}

- (CGSize)imageBrowerView:(XYImageBrowerView *)imageBrowerView imageSizeForIndex:(NSInteger)index {
    CGSize imageSize = [[self.imageSizes objectAtIndex:index] CGSizeValue];
    return imageSize;
}

- (UIImage *)imageBrowerView:(XYImageBrowerView *)imageBrowerView defaultImageForIndex:(NSInteger)index {
    return self.image;
}

- (NSString *)imageBrowerView:(XYImageBrowerView *)imageBrowerView pageTextAtIndex:(NSInteger)index {
    if (index < self.pageTextList.count) {
        return self.pageTextList[index];
    }
    return nil;
}

#pragma mark - lazy
- (XYImageBrowerView *)browerView {
    if (_browerView == nil) {
        _browerView = [[XYImageBrowerView alloc] init];
        _browerView.duration = 0.15;
        _browerView.delegate = self;
        [_browerView setDismissCallBack:^{
            _browerView = nil;
            _fromView = nil;
            _urlStrList = nil;
            _image = nil;
            _endViewBlock = nil;
        }];
    }
    return _browerView;
}

- (BOOL)isRequestFromNetwork {
    return _requestFromNetwork ?: NO;
}

- (void)dealloc {
    NSLog(@"%s", __func__);
}

@end


