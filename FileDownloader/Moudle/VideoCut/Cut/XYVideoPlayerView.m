//
//  XYVideoPlayerView.m
//  XYVideoCut
//
//  Created by mofeini on 16/11/14.
//  Copyright © 2016年 com.test.demo. All rights reserved.
//

#import "XYVideoPlayerView.h"
#import <AVFoundation/AVFoundation.h>

@implementation XYVideoPlayerView

+ (Class)layerClass {

    return [AVPlayerLayer class];
}

@end
