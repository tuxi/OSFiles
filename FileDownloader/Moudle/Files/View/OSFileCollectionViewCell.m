//
//  OSFileCollectionViewCell.m
//  FileDownloader
//
//  Created by Swae on 2017/10/29.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileCollectionViewCell.h"
#import "OSFileAttributeItem.h"

@interface OSFileCollectionViewCell ()

@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) UIButton *optionBtn;

@end

@implementation OSFileCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    
    self.contentView.layer.borderColor = [UIColor colorWithWhite:0.75 alpha:1.0].CGColor;
    self.contentView.layer.borderWidth = 0.5;
    self.contentView.backgroundColor = [UIColor whiteColor];
    [self.contentView addSubview:self.iconView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.subTitleLabel];
    [self.contentView addSubview:self.optionBtn];
    
    [self makeConstraints];
    
    [self.optionBtn setImage:[UIImage imageNamed:@"grid-options"] forState:UIControlStateNormal];
}

- (void)setFileModel:(OSFileAttributeItem *)fileModel {
    _fileModel = fileModel;
    
    BOOL isDirectory, fileExists;
    fileExists = [[NSFileManager defaultManager] fileExistsAtPath:fileModel.fullPath isDirectory:&isDirectory];
    self.titleLabel.text = [fileModel.fullPath lastPathComponent];
    if (isDirectory) {
        self.iconView.image = [UIImage imageNamed:@"table-folder"];
        self.subTitleLabel.text = [NSString stringWithFormat:@"%ld个文件", fileModel.subFileCount];
    } else if ([fileModel.fullPath.pathExtension.lowercaseString isEqualToString:@"png"] ||
               [fileModel.fullPath.pathExtension.lowercaseString isEqualToString:@"jpg"]) {
        self.iconView.image = [UIImage imageWithContentsOfFile:fileModel.fullPath];
    }
}


- (void)makeConstraints {
    NSDictionary *viewDict = @{@"iconView": self.iconView, @"titleLabel": self.titleLabel, @"subTitleLabel": self.subTitleLabel, @"optionBtn": self.optionBtn};
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(==30.0)-[iconView]-(==30.0)-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:viewDict]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(==10.0)-[iconView]-(==20.0)-[titleLabel]" options:kNilOptions metrics:nil views:viewDict]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.subTitleLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-3.0]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-3-[titleLabel]-3-|" options:kNilOptions metrics:nil views:viewDict]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-3-[subTitleLabel]-3-[optionBtn]|" options:kNilOptions metrics:nil views:viewDict]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.iconView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.iconView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.optionBtn attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.optionBtn attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.optionBtn attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:25.0]];
    
}

- (UIButton *)optionBtn {
    if (!_optionBtn) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn.titleLabel setFont:[UIFont systemFontOfSize:12]];
        _optionBtn = btn;
        btn.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _optionBtn;
}

- (UIImageView *)iconView {
    if (!_iconView) {
        UIImageView *view = [UIImageView new];
        _iconView = view;
        view.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _iconView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        UILabel *label = [UILabel new];
        label.lineBreakMode = NSLineBreakByTruncatingTail;
        _titleLabel = label;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_4) {
            [label setFont:[UIFont monospacedDigitSystemFontOfSize:13.0 weight:UIFontWeightRegular]];
        } else {
            [label setFont:[UIFont systemFontOfSize:13.0]];
        }
         _titleLabel.numberOfLines = 2;
    }
    return _titleLabel;
}

- (UILabel *)subTitleLabel {
    if (!_subTitleLabel) {
        UILabel *label = [UILabel new];
        label.lineBreakMode = NSLineBreakByTruncatingTail;
        _subTitleLabel = label;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_4) {
            [label setFont:[UIFont monospacedDigitSystemFontOfSize:13.0 weight:UIFontWeightRegular]];
        } else {
            [label setFont:[UIFont systemFontOfSize:13.0]];
        }
        _subTitleLabel.numberOfLines = 0;
    }
    return _subTitleLabel;
}
@end
