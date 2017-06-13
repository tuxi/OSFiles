//
//  XYCutVideoView.h
//  XYVideoCut
//
//  Created by mofeini on 16/11/14.
//  Copyright © 2016年 com.test.demo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ICGVideoTrimmerView.h"
#import "XYVideoPlayerView.h"

NS_ASSUME_NONNULL_BEGIN
@interface XYCutVideoView : UIView

+ (instancetype)cutVideoViewWithCompletionHandle:(void(^)(ICGVideoTrimmerView *cutView, XYVideoPlayerView *videoPlayerView))block;

@end
NS_ASSUME_NONNULL_END
