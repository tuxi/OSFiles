//
//  OSFileCollectionViewCell.m
//  FileDownloader
//
//  Created by Swae on 2017/10/29.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileCollectionViewCell.h"
#import "OSFileAttributeItem.h"
#import "UIImageView+XYExtension.h"
#import "NSString+OSFile.h"
#import "OSFileManager.h"

@interface OSFileCollectionViewCell ()

@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) UIButton *optionBtn;
@property (nonatomic, copy) NSString *renameNewName;

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
    
}

- (void)setStatus:(OSFileAttributeItemStatus)status {
    self.optionBtn.userInteractionEnabled = NO;
    self.contentView.layer.borderColor = [UIColor colorWithWhite:0.75 alpha:1.0].CGColor;
    switch (status) {
        case OSFileAttributeItemStatusDefault: {
            [self.optionBtn setImage:[UIImage imageNamed:@"grid-options"] forState:UIControlStateNormal];
            self.optionBtn.userInteractionEnabled = YES;
            break;
        }
        case OSFileAttributeItemStatusEdit: {
            [self.optionBtn setImage:[UIImage imageNamed:@"grid-selection"] forState:UIControlStateNormal];
            break;
        }
        case OSFileAttributeItemStatusChecked: {
            [self.optionBtn setImage:[UIImage imageNamed:@"grid-selected"] forState:UIControlStateNormal];
            self.contentView.layer.borderColor = [UIColor blueColor].CGColor;
            break;
        }
        default:
            break;
    }
}

- (void)setFileModel:(OSFileAttributeItem *)fileModel {
    _fileModel = fileModel;
    self.optionBtn.hidden = NO;
    [self setStatus:fileModel.status];
    
    /// 根据文件类型显示
    self.titleLabel.text = [fileModel.fullPath lastPathComponent];
    if (fileModel.isDirectory) {
        self.iconView.image = [UIImage imageNamed:@"table-folder"];
        self.subTitleLabel.text = [NSString stringWithFormat:@"%ld个文件", fileModel.subFileCount];
    }
    else {
        
        self.subTitleLabel.text = [fileModel.creationDate shortDateString];
        if (fileModel.isImage) {
            self.iconView.image = [UIImage imageWithContentsOfFile:fileModel.fullPath];
        } else if (fileModel.isVideo) {
            NSURL *videoURL = [NSURL fileURLWithPath:fileModel.fullPath];
            [self.iconView xy_imageWithMediaURL:videoURL placeholderImage:[UIImage imageNamed:@"table-fileicon-images"] completionHandlder:^(UIImage *image) {
                
            }];
        }
        else if (fileModel.isArchive) {
            self.iconView.image = [UIImage imageNamed:@"table-fileicon-archive"];
        }
        else if (fileModel.isWindows) {
            self.iconView.image = [UIImage imageNamed:@"table-foder-windows-smb"];
        }
        else {
            self.iconView.image = [UIImage imageNamed:@"table-fileicon-c-source"];
        }
    }
    
    if (fileModel.fullPath.length) {
        if ([fileModel.fullPath isEqualToString:[OSFileConfigUtils getDocumentPath]]) {
            self.titleLabel.text  = @"iTunes文件";
            self.iconView.image = [UIImage imageNamed:@"table-folder-itunes-files-sharing"];
            self.optionBtn.hidden = YES;
        }
        else if ([fileModel.fullPath isEqualToString:[OSFileConfigUtils getDownloadLocalFolderPath]]) {
            self.titleLabel.text  = @"下载";
            self.optionBtn.hidden = YES;
        }
    }
   
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
////////////////////////////////////////////////////////////////////////

- (void)optionBtnClick:(UIButton *)btn {
    
    [UIAlertView showWithTitle:nil message:nil style:UIAlertViewStyleDefault cancelButtonTitle:@"取消" otherButtonTitles:@[@"重命名", @"删除", @"共享", @"复制"] tapBlock:^(UIAlertView * _Nonnull alertView, NSInteger buttonIndex) {
        switch (buttonIndex) {
            case 0: { // cancel
                
                break;
            }
            case 1: {
                [self renameFile];
                break;
            }
            case 2: {
                [self deleteFile];
                break;
            }
            case 3: {
                [self shareFile];
                break;
            }
            case 4: {
                [self copyFile];
                break;
            }
            default:
                break;
        }
    }];
}

- (void)renameFile {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"rename" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = self.fileModel.filename;
        textField.placeholder = @"请输入需要修改的名字";
        [textField addTarget:self action:@selector(alertViewTextFieldtextChange:) forControlEvents:UIControlEventEditingChanged];
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        if ([self.renameNewName containsString:@"/"]) {
            [self showInfo:@"名称中不符合的字符"];
            return;
        }
        
        NSString *oldPath = self.fileModel.path;
        NSString *currentDirectory = [oldPath substringToIndex:oldPath.length-oldPath.lastPathComponent.length];
        NSString *newPath = [currentDirectory stringByAppendingPathComponent:self.renameNewName];
        BOOL res = [[NSFileManager defaultManager] fileExistsAtPath:newPath];
        if (res) {
            [self showInfo:@"存在同名的文件"];
            return;
        }
        NSError *moveError = nil;
        [[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:newPath error:&moveError];
        if (!moveError) {
            [newPath updateFileModificationDateForFilePath];
            [[NSFileManager defaultManager] removeItemAtPath:oldPath error:&moveError];
            self.fileModel.fullPath = newPath;
            if (self.delegate && [self.delegate respondsToSelector:@selector(fileCollectionViewCell:fileAttributeChange:)]) {
                [self.delegate fileCollectionViewCell:self fileAttributeChange:self.fileModel];
            }
        } else {
            NSLog(@"%@", moveError.localizedDescription);
        }
        self.renameNewName = nil;
    }]];
    [[UIViewController xy_topViewController] presentViewController:alert animated:true completion:nil];
}

- (void)alertViewTextFieldtextChange:(UITextField *)tf {
    self.renameNewName = tf.text;
}

- (void)deleteFile {
    if (self.delegate && [self.delegate respondsToSelector:@selector(fileCollectionViewCell:needDeleteFile:)]) {
        [self.delegate fileCollectionViewCell:self needDeleteFile:self.fileModel];
    }
}

- (void)shareFile {
    if (!self.fileModel) {
        return;
    }
    NSString *newPath = self.fileModel.path;
    NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:newPath.lastPathComponent];
    NSError *error = nil;
    [[NSFileManager defaultManager] copyItemAtPath:newPath toPath:tmpPath error:&error];
    
    if (error) {
        NSLog(@"ERROR: %@", error);
    }
    UIActivityViewController *shareActivity = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:tmpPath]] applicationActivities:nil];
    
    shareActivity.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
    };
    [[UIViewController xy_topViewController] presentViewController:shareActivity animated:YES completion:nil];
}

- (void)copyFile {
    if (self.delegate && [self.delegate respondsToSelector:@selector(fileCollectionViewCell:needCopyFile:)]) {
        [self.delegate fileCollectionViewCell:self needCopyFile:self.fileModel];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////


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
        [btn addTarget:self action:@selector(optionBtnClick:) forControlEvents:UIControlEventTouchUpInside];
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
            [label setFont:[UIFont monospacedDigitSystemFontOfSize:11.0 weight:UIFontWeightRegular]];
        } else {
            [label setFont:[UIFont systemFontOfSize:11.0]];
        }
        _subTitleLabel.numberOfLines = 1;
        _subTitleLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    }
    return _subTitleLabel;
}
@end
