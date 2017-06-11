//
//  OSFileDownloadCell.m
//  DownloaderManager
//
//  Created by xiaoyuan on 2017/6/5.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileDownloadCell.h"
#import "OSFileDownloadItem.h"
#import "AppDelegate.h"
#import "OSDownloaderManager.h"
#import "FFCircularProgressView.h"

#pragma clang diagnostic ignored "-Wdeprecated-declarations"

static CGFloat const OSFileDownloadCellGloabMargin = 10.0;

@interface OSFileDownloadCell () <UIAlertViewDelegate>

@property (weak, nonatomic) UILabel *downloadStatusLabel;
@property (weak, nonatomic) FFCircularProgressView *cycleView;
@property (weak, nonatomic) UILabel *fileNameLabel;
@property (weak, nonatomic) UILabel *remainTimeLabel;
@property (weak, nonatomic) UIButton *downloadStatusBtn;
@property (weak, nonatomic) UIButton *moreBtn;
@property (weak, nonatomic) UIImageView *iconView;
@property (weak, nonatomic) UILabel *speedLabel;
@property (weak, nonatomic) UIView *bottomLine;

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGes;

@property (nonatomic, copy) void (^longPressGesOnSelfHandlerBlock)(UILongPressGestureRecognizer *longPres);

@end

@implementation OSFileDownloadCell


#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~ initialize ~~~~~~~~~~~~~~~~~~~~~~

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setLongPressGestureRecognizer:(void (^)(UILongPressGestureRecognizer *longPres))block {
    if (!self.longPressGes) {
        self.longPressGes = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGesOnSelfHandler:)];
        [self addGestureRecognizer:self.longPressGes];
    }
    self.longPressGesOnSelfHandlerBlock = nil;
    self.longPressGesOnSelfHandlerBlock = block;
}

- (void)longPressGesOnSelfHandler:(UILongPressGestureRecognizer *)longPress {
    
    [self _longPressGesOnSelfHandler:longPress];
    
    
}

- (void)_longPressGesOnSelfHandler:(UILongPressGestureRecognizer *)longPress {
    if (self.longPressGesOnSelfHandlerBlock) {
        self.longPressGesOnSelfHandlerBlock(longPress);
    }
    
}

- (void)setup {
    
    self.iconView.image = [UIImage imageNamed:@"TabBrowser"];
    self.fileNameLabel.text = @"fileName";
    self.downloadStatusLabel.text = @"0.0KB of 0.0KB";
    [self.moreBtn setTitle:@"•••" forState:UIControlStateNormal];
    [self.moreBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.cycleView startSpinProgressBackgroundLayer];
    [self.cycleView setProgress:1.0];
    self.bottomLine.backgroundColor = [UIColor colorWithWhite:0.6 alpha:0.8];
    [self.speedLabel setText:@"0.0KB/s"];
    [self.remainTimeLabel setText:@"0s"];
    
    [self _makeConstraints];
    __weak typeof(self) weakSelf = self;
    [self setLongPressGestureRecognizer:^(UILongPressGestureRecognizer *longPres) {
        if (longPres.state == UIGestureRecognizerStateBegan) {
            [[[UIAlertView alloc] initWithTitle:@"是否删除下载项" message:nil delegate:weakSelf cancelButtonTitle:@"否" otherButtonTitles:@"是", nil] show];
        }
    }];
}

//- (void)layoutSubviews {
//    
//    [super layoutSubviews];
//    [self _makeConstraints];
//}

#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~ update subviews ~~~~~~~~~~~~~~~~~~~~~~
- (void)setDownloadItem:(OSFileDownloadItem *)downloadItem {
    _downloadItem = downloadItem;
    
    [self setDownloadViewByStatus:downloadItem.status];
    
    [self setProgress];
    
    [self.fileNameLabel setText:self.downloadItem.fileName];
    
 
}

- (void)setDownloadViewByStatus:(OSFileDownloadStatus)aStatus {
    
    self.downloadStatusLabel.hidden = NO;
    self.speedLabel.hidden = NO;
    self.remainTimeLabel.hidden = NO;

    switch (aStatus) {
            
        case OSFileDownloadStatusNotStarted:


            break;
            
        case OSFileDownloadStatusStarted:
        {
            NSString *receivedFileSize = [NSString transformedFileSizeValue:@(self.downloadItem.progressObj.receivedFileSize)];
            NSString *expectedFileTotalSize = [NSString transformedFileSizeValue:@(self.downloadItem.progressObj.expectedFileTotalSize)];
            
            NSString *downloadFileSizeStr = [NSString stringWithFormat:@"%@ of %@", receivedFileSize, expectedFileTotalSize];
            [self.downloadStatusLabel setText:downloadFileSizeStr];
            
            
            [self.remainTimeLabel setText:[NSString stringWithRemainingTime:self.downloadItem.progressObj.estimatedRemainingTime]];
            [self.speedLabel setText:[NSString stringWithFormat:@"%@/s", [NSString transformedFileSizeValue:@(self.downloadItem.progressObj.bytesPerSecondSpeed)]]];
        }
            break;
        case OSFileDownloadStatusPaused:
            
            break;
            
        case OSFileDownloadStatusSuccess:
        {
            self.downloadStatusLabel.hidden = YES;
            self.speedLabel.hidden = YES;
            self.remainTimeLabel.hidden = YES;
        }
            break;
            
        case OSFileDownloadStatusCancelled:
         
            break;
            
        case OSFileDownloadStatusFailure:
          
            break;
        case OSFileDownloadStatusInterrupted:
          
            break;
            
        default:
            break;
    }
    
    

}

- (void)setProgress {
    
    OSDownloadProgress *progress = self.downloadItem.progressObj;
    if (progress) {
        self.cycleView.progress = progress.progress;
        if (progress) {
            [self.cycleView stopSpinProgressBackgroundLayer];
        }
    } else {
        if (self.downloadItem.status == OSFileDownloadStatusSuccess) {
            self.cycleView.progress = 1.0;
            [self.cycleView stopSpinProgressBackgroundLayer];
        } else {
            self.cycleView.progress = 0.0;
        }
    }
        
}

#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~ Actions ~~~~~~~~~~~~~~~~~~~~~~

- (void)pause:(NSString *)urlPath {
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate.downloadModule pause:urlPath];
    
}

- (void)resume:(NSString *)urlPath {
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate.downloadModule resume:urlPath];
}

- (void)start:(OSFileDownloadItem *)downloadItem {
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate.downloadModule start:downloadItem];
}

- (void)cycleViewClick:(FFCircularProgressView *)cycleView {
    
    switch (self.downloadItem.status) {
            
        case OSFileDownloadStatusNotStarted:
        {
            [self start:self.downloadItem];
        }
            break;
            
        case OSFileDownloadStatusStarted:
        {
            [self pause:self.downloadItem.urlPath];
        }
            break;
        case OSFileDownloadStatusPaused:
        {
            [self resume:self.downloadItem.urlPath];
        }
            break;
            
        case OSFileDownloadStatusSuccess:
        {
            
        }
            break;
            
        case OSFileDownloadStatusCancelled:
        {
            
        }
            break;
            
        case OSFileDownloadStatusFailure:
        case OSFileDownloadStatusInterrupted:
        {
            [self start:self.downloadItem];
        }
            break;
            
        default:
            break;
    }
    
}

#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ <UIAlertViewDelegate> ~~~~~~~~~~~~~~~~~~~~~~~

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 1) {
        // 取消下载，并删除
        AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [delegate.downloadModule cancel:self.downloadItem.urlPath];
    }
}

#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ Layout ~~~~~~~~~~~~~~~~~~~~~~~

- (void)_makeConstraints {
    [_iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).mas_offset(OSFileDownloadCellGloabMargin);
        make.centerY.equalTo(self.contentView);
        make.width.height.mas_equalTo(38);
    }];
    
    [_fileNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        if (_iconView) {
            make.left.equalTo(_iconView.mas_right).mas_offset(OSFileDownloadCellGloabMargin);
        }
        make.top.equalTo(self.contentView).mas_offset(5);
        make.left.equalTo(self.contentView).mas_offset(OSFileDownloadCellGloabMargin).priorityHigh();
        make.right.equalTo(self.contentView).mas_offset(-100);
        if (_downloadStatusLabel) {
            make.bottom.lessThanOrEqualTo(_downloadStatusLabel.mas_top).mas_offset(-3);
        }
        make.bottom.equalTo(self.contentView.mas_bottom).mas_offset(-5).priorityHigh();
    }];

    [_downloadStatusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_fileNameLabel);
        make.bottom.equalTo(self.contentView).mas_offset(-5);
    }];
    
    [_moreBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).mas_offset(-OSFileDownloadCellGloabMargin);
        make.centerY.equalTo(self.contentView);
    }];
    
    [_cycleView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (_moreBtn) {
            make.right.equalTo(_moreBtn.mas_left).mas_offset(-5);
        }
        make.centerY.equalTo(self.contentView);
        make.width.height.mas_equalTo(25);
    }];
    
    [_bottomLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).mas_offset(OSFileDownloadCellGloabMargin);
        make.bottom.right.equalTo(self.contentView);
        make.height.mas_offset(0.5);
    }];
    
    if (_downloadStatusLabel) {
        [_speedLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_downloadStatusLabel.mas_right).mas_offset(OSFileDownloadCellGloabMargin);
            make.top.bottom.equalTo(_downloadStatusLabel);
        }];
        
        [_remainTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_speedLabel.mas_right).mas_offset(5.0);
            make.top.bottom.equalTo(_downloadStatusLabel);
        }];
    }
}


#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ Lazy ~~~~~~~~~~~~~~~~~~~~~~~

- (UILabel *)fileNameLabel {
    if (!_fileNameLabel) {
        UILabel *label = [UILabel new];
        label.lineBreakMode = NSLineBreakByTruncatingTail;
        _fileNameLabel = label;
        [self.contentView addSubview:label];
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_4) {
            [label setFont:[UIFont monospacedDigitSystemFontOfSize:13.0 weight:UIFontWeightRegular]];
        } else {
            [label setFont:[UIFont systemFontOfSize:13.0]];
        }
    }
    return _fileNameLabel;
}

- (UILabel *)downloadStatusLabel {
    if (!_downloadStatusLabel) {
        UILabel *label = [UILabel new];
        _downloadStatusLabel = label;
        [self.contentView addSubview:label];
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_4) {
            [label setFont:[UIFont monospacedDigitSystemFontOfSize:10.0 weight:UIFontWeightRegular]];
        } else {
            [label setFont:[UIFont systemFontOfSize:10.0]];
        }
    }
    return _downloadStatusLabel;
}

- (UILabel *)speedLabel {
    if (!_speedLabel) {
        UILabel *label = [UILabel new];
        _speedLabel = label;
        [self.contentView addSubview:label];
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_4) {
            [label setFont:[UIFont monospacedDigitSystemFontOfSize:10.0 weight:UIFontWeightRegular]];
        } else {
            [label setFont:[UIFont systemFontOfSize:10.0]];
        }
    }
    return _speedLabel;
}

- (UILabel *)remainTimeLabel {
    if (!_remainTimeLabel) {
        UILabel *label = [UILabel new];
        _remainTimeLabel = label;
        [self.contentView addSubview:label];
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_4) {
            [label setFont:[UIFont monospacedDigitSystemFontOfSize:10.0 weight:UIFontWeightRegular]];
        } else {
            [label setFont:[UIFont systemFontOfSize:10.0]];
        }
    }
    return _remainTimeLabel;
}


- (FFCircularProgressView *)cycleView {
    if (!_cycleView) {
        
        FFCircularProgressView *cycleView = [[FFCircularProgressView alloc] init];
        _cycleView = cycleView;
        [self.contentView addSubview:cycleView];
        [cycleView addTarget:self action:@selector(cycleViewClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cycleView;
}

- (UIButton *)downloadStatusBtn {
    if (!_downloadStatusBtn) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        _downloadStatusBtn = btn;
        [self.contentView addSubview:btn];
    }
    return _downloadStatusBtn;
}

- (UIButton *)moreBtn {
    if (!_moreBtn) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        _moreBtn = btn;
        [self.contentView addSubview:btn];
    }
    return _moreBtn;
}

- (UIImageView *)iconView {
    if (!_iconView) {
        UIImageView *view = [UIImageView new];
        _iconView = view;
        [self.contentView addSubview:view];
    }
    return _iconView;
}

- (UIView *)bottomLine {
    if (!_bottomLine) {
        UIView *view = [UIView new];
        _bottomLine = view;
        [self.contentView addSubview:view];
    }
    return _bottomLine;
}

@end

@implementation NSString (DownloadUtils)

// 转换文件的字节数
+ (NSString *)transformedFileSizeValue:(NSNumber *)value {
    
    double convertedValue = [value doubleValue];
    int multiplyFactor = 0;
    
    NSArray *tokens = [NSArray arrayWithObjects:@"B",@"KB",@"MB",@"GB",@"TB",@"PB", @"EB", @"ZB", @"YB",nil];
    
    while (convertedValue > 1024) {
        convertedValue /= 1024;
        multiplyFactor++;
    }
    
    return [NSString stringWithFormat:@"%4.2f %@",convertedValue, [tokens objectAtIndex:multiplyFactor]];
}

+ (NSString *)stringWithRemainingTime:(NSTimeInterval)remainingTime {
    NSNumberFormatter *aNumberFormatter = [[NSNumberFormatter alloc] init];
    [aNumberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [aNumberFormatter setMinimumFractionDigits:1];
    [aNumberFormatter setMaximumFractionDigits:1];
    [aNumberFormatter setDecimalSeparator:@"."];
    return [NSString stringWithFormat:@"%@ s", [aNumberFormatter stringFromNumber:@(remainingTime)]];
}


@end
