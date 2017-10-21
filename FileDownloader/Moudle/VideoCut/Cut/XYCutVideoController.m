//
//  XYCutVideoController.m
//  XYVideoCut
//
//  Created by mofeini on 16/11/14.
//  Copyright © 2016年 com.test.demo. All rights reserved.
//

#import "XYCutVideoController.h"
#import "XYCutVideoView.h"
#import "XYMenuView.h"
#import "UIButton+ClickBlock.h"

@interface XYCutVideoController () <ICGVideoTrimmerDelegate>

@property (nonatomic, weak) XYVideoPlayerView *videoPlayerView;
@property (nonatomic, weak) ICGVideoTrimmerView *cutView;

@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) CGFloat startTime;
@property (nonatomic, assign) CGFloat stopTime;
@property (nonatomic, assign) CGFloat videoPlaybackPosition;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, copy) NSString *tempVideoPath;

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVAsset *asset;

@property (nonatomic, strong) AVAssetExportSession *exportSession;

@property (nonatomic, weak) XYMenuView *menuView;

@end

@implementation XYCutVideoController

- (XYMenuView *)menuView {
    if (_menuView == nil) {
        XYMenuView *menuView = [XYMenuView menuViewToSuperView:self.view];
        [menuView setMenuViewClickBlock:^(XYMenuViewBtnType type) {
            switch (type) {
                case XYMenuViewBtnTypeFastExport:
                    [self.menuView dismissMenuView];
                    [self exportVideoWithPressName:AVAssetExportPreset640x480];
                    break;
                case XYMenuViewBtnTypeHDExport:
                    [self.menuView dismissMenuView];
                    [self exportVideoWithPressName:AVAssetExportPreset1280x720];
                    break;
                case XYMenuViewBtnTypeSuperClear:
                    [self.menuView dismissMenuView];
                    [self exportVideoWithPressName:AVAssetExportPreset1920x1080];
                    break;
                case XYMenuViewBtnTypeCancel:
                    
                    break;
            }
        }];
        self.menuView = menuView;
    }
    return _menuView;
}

#pragma mark - View Controller View Life
- (void)loadView {
    
    self.view = [XYCutVideoView cutVideoViewWithCompletionHandle:^(ICGVideoTrimmerView * _Nonnull cutView, XYVideoPlayerView * _Nonnull videoPlayerView) {
        self.videoPlayerView = videoPlayerView;
        self.cutView = cutView;
    }];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tempVideoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tempVideo.mov"];
    self.view.backgroundColor = [UIColor colorWithRed:56/255.0 green:55/255.0 blue:53/255.0 alpha:1];
    
    [self pickerFinishPickingMedia];
    // 禁止系统手势
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    self.title = @"剪辑视频";
    __weak typeof(self) weakSelf = self;
    [UIButton xy_button:^(UIButton *btn) {
        [btn setTitle:@"导出" forState:UIControlStateNormal];
        [btn sizeToFit];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
        
    } buttonClickCallBack:^(UIButton *btn) {
        if (!weakSelf.menuView.hidden) {
            [weakSelf.menuView dismissMenuView:^{
            }];
        } else if (weakSelf.menuView.hidden) {
            // 弹出导出选项
            [weakSelf.menuView showMenuView:^{
                [weakSelf.player pause];
                [weakSelf stopPlaybackTimeChecker];
                weakSelf.isPlaying = NO;
            }];
        }
        
    }];

}

- (void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];
    [self tapOnVideoPlayerView:nil];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];
    [self tapOnVideoPlayerView:nil];
}


- (void)pickerFinishPickingMedia {

     // 1.取出选中视频的URL
//    NSURL *videoURL = [self.infoDict objectForKey:@"UIImagePickerControllerMediaURL"];
    NSURL *videoURL = self.videoURL;
    
    // 2.设置playerLayer
    AVAsset *asset = [AVAsset assetWithURL:videoURL];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    // 将videoPlayerView的layer转换为AVPlayerLayer
    AVPlayerLayer *playerLayer = (AVPlayerLayer *)self.videoPlayerView.layer;
    [playerLayer setPlayer:player];
    
    // 设置视频播放的拉伸效果\等比例拉伸
    playerLayer.contentsGravity = AVLayerVideoGravityResizeAspect;
    // 当播放完成时不做任何事情
    player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    
    // 3.添加手势到videoPlayerView
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnVideoPlayerView:)];
    [self.videoPlayerView addGestureRecognizer:tap];
    
    // 4.设置cutView
    self.cutView.themeColor = [UIColor lightGrayColor]; // 设置视频修剪器的主题颜色
    [self.cutView setAsset:asset]; // 设置要剪辑的媒体资源
    [self.cutView setShowsRulerView:NO]; // 显示视图修剪器上的标尺
    self.cutView.trackerColor = [UIColor yellowColor]; // 设置跟踪器上的颜色
    [self.cutView setDelegate:self];
    [self.cutView resetSubviews]; // 重新设置子控件
    
    
    
    self.player = player;
    self.asset = asset;
}

#pragma mark - ICGVideoTrimmerDelegate
- (void)trimmerView:(ICGVideoTrimmerView *)trimmerView didChangeLeftPosition:(CGFloat)startTime rightPosition:(CGFloat)endTime {

    if (startTime != self.startTime) {
        [self seekVideoToPos:startTime];
    }
    
    // 记录开始时间和结束时间
    self.startTime = startTime;
    self.stopTime = endTime;
}

#pragma mark - Actions
- (void)exportVideoWithPressName:(NSString *)pressName {

    // 删除缓存中的临时视频文件
    [self deleteTempVideoFile];
    
    // 获取渲染参数预设的标识符
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:self.asset];
    if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality]) {
        // 如果包含中等质量 就配置渲染参数并导出视频AVAssetExportPresetPassthrough
        AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:self.asset presetName:pressName];
        self.exportSession = exportSession;
        
        // 设置输出的路径
        exportSession.outputURL = [NSURL fileURLWithPath:self.tempVideoPath];
        // 设置输出文件的格式
        exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        
        // 设置导出视频的range
        // 视频的开始位置
        CMTime start = CMTimeMakeWithSeconds(self.startTime, self.asset.duration.timescale);
        // 视频的持续时间
        CMTime duration = CMTimeMakeWithSeconds(self.stopTime - self.startTime, self.asset.duration.timescale);
        self.exportSession.timeRange = CMTimeRangeMake(start, duration);
        
        // 异步导出视频
        [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
            // 根据导出的状态做响应的操作，当导出成功时，回到主线程保存视频
            switch (self.exportSession.status) {
                case AVAssetExportSessionStatusFailed:
                    NSLog(@"Export failed - %@", [self.exportSession.error localizedDescription]);
                    break;
                case AVAssetExportSessionStatusCancelled:
                    NSLog(@"Export canceled");
                    break;
                case AVAssetExportSessionStatusExporting:
                    NSLog(@"Exporting now");
                    break;
                default:
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSURL *movieURL = [NSURL fileURLWithPath:self.tempVideoPath];
                        UISaveVideoAtPathToSavedPhotosAlbum([movieURL relativePath], self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
                    });
                    break;
            }
        }];
    }

}


// 点按videoLayer的手势
- (void)tapOnVideoPlayerView:(UITapGestureRecognizer *)tap {
    
    if (self.isPlaying) {
        [self.player pause];
        [self stopPlaybackTimeChecker];
    } else {
        [self.player play];
        // 开始播放时间检测
        [self startPlaybackTimeChecker];
    }
    
    self.isPlaying = !self.isPlaying;
    // 当不在播放时隐藏跟踪器
    [self.cutView hideTracker:!self.isPlaying];
}

#pragma mark - 视频播放时间的检测
- (void)stopPlaybackTimeChecker {
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
    
    NSLog(@"%@", self.displayLink);
}

- (void)startPlaybackTimeChecker {
    
    [self stopPlaybackTimeChecker]; // 停止检测
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onPlaybackTimeCheckerTimer)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)onPlaybackTimeCheckerTimer {
    // 让视频当前播放的时间跟随播放器
    self.videoPlaybackPosition = CMTimeGetSeconds([self.player currentTime]);
    [self.cutView seekToTime:CMTimeGetSeconds([self.player currentTime])];
    
    // 当视频播放完后，重置开始时间
    if (self.videoPlaybackPosition >= self.stopTime) {
        self.videoPlaybackPosition = self.startTime;
        [self.cutView seekToTime:self.startTime];
        [self seekVideoToPos:self.startTime];
    }
}

- (void)seekVideoToPos:(CGFloat)pos {

    self.videoPlaybackPosition = pos;
    CMTime time = CMTimeMakeWithSeconds(self.videoPlaybackPosition, self.player.currentTime.timescale);
    [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

#pragma mark - Private 
- (void)deleteTempVideoFile {
    
    NSURL *url = [NSURL fileURLWithPath:self.tempVideoPath];
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:self.tempVideoPath];
    NSError *error;
    // 判断文件是否存在
    if (exist) {
        [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
        NSLog(@"file delected");
        if (error) {
            NSLog(@"file remove error - %@", error.localizedDescription);
        }
    } else {
        NSLog(@"no file by that time");
    }
}
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    
    [self.player pause];
    
    NSLog(@"%@", videoPath);
    
    if (error) {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Video Saved" message:@"Save To Photo Album" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    }
}


- (void)dealloc {
    
    [self.player pause];

    NSLog(@"%s", __func__);
}
@end
