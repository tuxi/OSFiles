//
//  XYImageViewer.h
//  image-viewer
//
//  Created by mofeini on 17/1/5.
//  Copyright © 2017年 com.test.demo. All rights reserved.
//

#import "XYImageBrowerView.h"

@interface XYImageViewer : NSObject

@property (nonatomic, strong, readonly) XYImageBrowerView *browerView;

/**
 *  准备需要展示的图片的各种数据
 *
 * @param   URLList  图片的url 字符串数组
 * @param   endViewBlock  当点击图片时动画结束到的视图---block:回调给外界索引值，外界根据索引值找到要结束的视图
 * 注意: 当调用此方法时，又调用了prepareImages:endView会抛异常
 */
+ (instancetype)prepareImageURLList:(NSArray<NSString *> *)URLList
                       pageTextList:(NSArray<NSString *> *)pageTextList
                            endView:(UIView *(^)(NSIndexPath *indexPath))endViewBlock;


/**
 *  准备需要展示的图片的各种数据
 *
 * @param   images  需要展示的图片数组
 * @param   endViewBlock  动画结束的视图---block:回调给外界当前查看图片的索引值，外界根据索引值找到要结束的视图
 */
+ (instancetype)prepareImages:(NSArray<NSString*> *)images
                 pageTextList:(NSArray<NSString *> *)pageTextList
                      endView:(UIView *(^)(NSIndexPath *indexPath))endViewBlock;

/**
 *  显示图片浏览器
 *
 * @param   fromView  用户点击的视图，图片这个视图开始做动画，并打开图片浏览器
 * @param   currentIndex  当前点击图片的索引值
 */
- (XYImageBrowerView *)show:(UIView *)fromView
               currentIndex:(NSInteger)currentIndex;

/**
 * 弹出图片播放器
 *
 * @param   URLList  需要展示的图片url字符串数组
 * @param   currentIndex  从哪个图片开始
 * @param   fromView  开始展示的视图，主要用于做开始动画的
 * @return  endView  关闭图片浏览器时，动画结束在的视图，block回调了结束时的索引
 */
- (XYImageBrowerView *)showWithImageURLList:(NSArray<NSString *> *)URLList
                               currentIndex:(NSInteger)currentIndex
                                   fromView:(UIView *)fromView
                                    endView:(UIView *(^)(NSIndexPath *indexPath))endViewBlock;

@end


