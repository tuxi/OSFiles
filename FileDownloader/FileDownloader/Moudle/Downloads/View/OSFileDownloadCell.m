//
//  OSFileDownloadCell.m
//  DownloaderManager
//
//  Created by xiaoyuan on 2017/6/5.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileDownloadCell.h"
#import "OSFileItem.h"
#import "AppDelegate.h"
#import "OSDownloaderManager.h"
#import "FFCircularProgressView.h"
#import "NSString+FileDownloadsExtend.h"

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
@property (weak, nonatomic) UILabel *fileSizeLabel;

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
    self.bottomLine.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.8];
    [self.speedLabel setText:@"0.0KB/s"];
    [self.remainTimeLabel setText:@"0s"];
    
    [self _makeConstraints];
   
}

#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ cell config ~~~~~~~~~~~~~~~~~~~~~~~

- (void)xy_configCellByModel:(id)model indexPath:(NSIndexPath *)indexPath {
    self.downloadItem = model;
    
}



#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~ update subviews ~~~~~~~~~~~~~~~~~~~~~~
- (void)setDownloadItem:(OSFileItem *)downloadItem {
    _downloadItem = downloadItem;
    
    [self setDownloadViewByStatus:downloadItem.status];
    
    [self setProgress];
    
    [self.fileNameLabel setText:self.downloadItem.fileName];
    
 
}

- (void)setDownloadViewByStatus:(OSFileDownloadStatus)aStatus {
    
    self.downloadStatusLabel.hidden = NO;
    self.speedLabel.hidden = NO;
    self.remainTimeLabel.hidden = NO;
    self.cycleView.hidden = NO;
    self.fileSizeLabel.hidden = YES;
    self.iconView.hidden = YES;
    self.iconView.image = [UIImage imageNamed:@"TabBrowser"];
    
    NSString *receivedFileSize = [NSString transformedFileSizeValue:@(self.downloadItem.progressObj.receivedFileSize)];
    NSString *expectedFileTotalSize = [NSString transformedFileSizeValue:@(self.downloadItem.progressObj.expectedFileTotalSize)];
    
    NSString *downloadFileSizeStr = [NSString stringWithFormat:@"%@ of %@", receivedFileSize, expectedFileTotalSize];
    [self.downloadStatusLabel setText:downloadFileSizeStr];
    
    
    [self.remainTimeLabel setText:[NSString stringWithRemainingTime:self.downloadItem.progressObj.estimatedRemainingTime]];
    [self.speedLabel setText:[NSString stringWithFormat:@"%@/s", [NSString transformedFileSizeValue:@(self.downloadItem.progressObj.bytesPerSecondSpeed)]]];
    
    self.cycleView.circularState = FFCircularStateIcon;
    
    NSData *data = [NSData dataWithContentsOfURL:self.downloadItem.localFileURL];
    if (data) {
        
    }
    
    switch (aStatus) {
            
        case OSFileDownloadStatusNotStarted:
            self.cycleView.circularState = FFCircularStateIcon;

            break;
            
        case OSFileDownloadStatusStarted:
        {
           self.cycleView.circularState = FFCircularStateStopProgress;
        }
            break;
        case OSFileDownloadStatusPaused:
            self.cycleView.circularState = FFCircularStateIcon;
            break;
            
        case OSFileDownloadStatusSuccess:
        {
            self.downloadStatusLabel.hidden = YES;
            self.speedLabel.hidden = YES;
            self.remainTimeLabel.hidden = YES;
            self.cycleView.hidden = YES;
            self.fileSizeLabel.hidden = NO;
            self.iconView.hidden = NO;
            NSString *expectedFileTotalSize = [NSString transformedFileSizeValue:@(self.downloadItem.progressObj.expectedFileTotalSize)];
            [self.fileSizeLabel setText:expectedFileTotalSize];
            self.cycleView.circularState = FFCircularStateCompleted;
            NSLog(@"MIMEType:(%@) (%@, %d)", self.downloadItem.MIMEType, [NSString stringWithUTF8String:__FILE__].lastPathComponent, __LINE__);
            if ([self.downloadItem.MIMEType isEqualToString:@"image/jpeg"] || [self.downloadItem.MIMEType isEqualToString:@"image/png"]) {
                NSData *data = [NSData dataWithContentsOfURL:self.downloadItem.localFileURL];
                self.iconView.image = [UIImage imageWithData:data];
            }
        }
            break;
            
        case OSFileDownloadStatusCancelled:
         
            break;
            
        case OSFileDownloadStatusFailure:
          self.cycleView.circularState = FFCircularStateStopSpinning;
            break;
        case OSFileDownloadStatusInterrupted:
          self.cycleView.circularState = FFCircularStateStopSpinning;
            break;
            
        default:
            break;
    }
    
    [self _makeConstraints];
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

- (void)start:(OSFileItem *)downloadItem {
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



#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ Layout ~~~~~~~~~~~~~~~~~~~~~~~

- (void)_makeConstraints {
    [_iconView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).mas_offset(OSFileDownloadCellGloabMargin);
        make.centerY.equalTo(self.contentView);
        make.width.height.mas_equalTo(38);
    }];
    
    [_fileNameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        if (_iconView && _iconView.hidden == NO) {
            make.left.equalTo(_iconView.mas_right).mas_offset(OSFileDownloadCellGloabMargin);
        } else {
            make.left.equalTo(self.contentView).mas_offset(OSFileDownloadCellGloabMargin);
        }
        make.top.equalTo(self.contentView).mas_offset(8.8);
        make.right.equalTo(self.contentView).mas_offset(-100);
        if (_downloadStatusLabel && _downloadStatusLabel.hidden == NO) {
            make.bottom.lessThanOrEqualTo(_downloadStatusLabel.mas_top).mas_offset(-3);
        } else {
            make.bottom.equalTo(self.contentView.mas_bottom).mas_offset(-8.8);
        }
    }];
    
    [_downloadStatusLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_fileNameLabel);
        make.bottom.equalTo(self.contentView).mas_offset(-8.8);
    }];
    
    [_moreBtn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).mas_offset(-OSFileDownloadCellGloabMargin);
        make.centerY.equalTo(self.contentView);
    }];
    
    [_cycleView mas_remakeConstraints:^(MASConstraintMaker *make) {
        if (_moreBtn && _moreBtn.hidden == NO) {
            make.right.equalTo(_moreBtn.mas_left).mas_offset(-5);
        }
        make.centerY.equalTo(self.contentView);
        make.width.height.mas_equalTo(25);
    }];
    
    [_bottomLine mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).mas_offset(OSFileDownloadCellGloabMargin);
        make.bottom.right.equalTo(self.contentView);
        make.height.mas_offset(0.5);
    }];
    
    if (_downloadStatusLabel) {
        [_speedLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_downloadStatusLabel.mas_right).mas_offset(OSFileDownloadCellGloabMargin);
            make.top.bottom.equalTo(_downloadStatusLabel);
        }];
        
        [_remainTimeLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_speedLabel.mas_right).mas_offset(OSFileDownloadCellGloabMargin);
            make.top.bottom.equalTo(_downloadStatusLabel);
        }];
    }
    
    if (_fileSizeLabel && _fileSizeLabel.hidden == NO) {
        [_fileSizeLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            if (_moreBtn.hidden == NO) {
                make.right.equalTo(_moreBtn.mas_left).mas_offset(-5);
            }
            make.centerY.equalTo(self.contentView);
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
            [label setFont:[UIFont monospacedDigitSystemFontOfSize:9.0 weight:UIFontWeightRegular]];
        } else {
            [label setFont:[UIFont systemFontOfSize:9.0]];
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
            [label setFont:[UIFont monospacedDigitSystemFontOfSize:9.0 weight:UIFontWeightRegular]];
        } else {
            [label setFont:[UIFont systemFontOfSize:9.0]];
        }
    }
    return _remainTimeLabel;
}

- (UILabel *)fileSizeLabel {
    if (!_fileSizeLabel) {
        UILabel *label = [UILabel new];
        label.hidden = YES;
        _fileSizeLabel = label;
        [self.contentView addSubview:label];
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_4) {
            [label setFont:[UIFont monospacedDigitSystemFontOfSize:11.0 weight:UIFontWeightRegular]];
        } else {
            [label setFont:[UIFont systemFontOfSize:11.0]];
        }
    }
    return _fileSizeLabel;
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
        [btn.titleLabel setFont:[UIFont systemFontOfSize:12]];
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


