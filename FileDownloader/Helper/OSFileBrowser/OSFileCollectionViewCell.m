//
//  OSFileCollectionViewCell.m
//  FileBrowser
//
//  Created by xiaoyuan on 05/08/2014.
//  Copyright © 2014 xiaoyuan. All rights reserved.
//

#import "OSFileCollectionViewCell.h"
#import "OSFileAttributeItem.h"
#import "UIImageView+XYExtension.h"
#import "NSString+OSFile.h"
#import "OSFileManager.h"
#import "NSDate+ESUtilities.h"
#import "UIViewController+XYExtensions.h"
#import "MBProgressHUD+BBHUD.h"
#import "UIImage+XYImage.h"
#import "OSFileCollectionViewFlowLayout.h"

@interface OSFileCollectionViewCell ()

@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) UIButton *optionBtn;
@property (nonatomic, copy) NSString *renameNewName;
@property (nonatomic, strong) NSArray *constraints;

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
            [self.optionBtn setImage:[UIImage OSFileBrowserImageNamed:@"grid-options"] forState:UIControlStateNormal];
            self.optionBtn.userInteractionEnabled = YES;
            break;
        }
        case OSFileAttributeItemStatusEdit: {
            [self.optionBtn setImage:[UIImage OSFileBrowserImageNamed:@"grid-selection"] forState:UIControlStateNormal];
            break;
        }
        case OSFileAttributeItemStatusChecked: {
            [self.optionBtn setImage:[UIImage OSFileBrowserImageNamed:@"grid-selected"] forState:UIControlStateNormal];
            if (!self.fileModel.isRootDirectory) {
                self.contentView.layer.borderColor = [UIColor colorWithRed:92/255.0 green:183/255.0 blue:235/255.0 alpha:1.0].CGColor;
            }
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
    self.titleLabel.text = fileModel.displayName;
    if (fileModel.isDirectory) {
        self.iconView.image = fileModel.icon;
        self.subTitleLabel.text = [NSString stringWithFormat:@"%ld个文件", fileModel.numberOfSubFiles];
    }
    else {
        
        self.subTitleLabel.text = [fileModel.creationDate shortDateString];
        if (fileModel.isImage) {
            self.iconView.image = [UIImage imageWithContentsOfFile:fileModel.path];
        } else if (fileModel.isVideo) {
            NSURL *videoURL = [NSURL fileURLWithPath:fileModel.path];
            [self.iconView xy_imageWithMediaURL:videoURL placeholderImage:[UIImage OSFileBrowserImageNamed:@"table-fileicon-images"] completionHandlder:^(UIImage *image) {
                
            }];
        }
        else {
            self.iconView.image = fileModel.icon;
        }
    }
    if ([self.fileModel isRootDirectory]) {
        self.optionBtn.hidden = YES;
    }
    
    /// 对标记为需要重新布局的视图，刷新
    if (self.fileModel.needReLoyoutItem) {
        [self invalidateConstraints];
        self.fileModel.needReLoyoutItem = NO;
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
////////////////////////////////////////////////////////////////////////

- (void)optionBtnClick:(UIButton *)btn {
    UIAlertController *alVc = [UIAlertController alertControllerWithTitle:self.fileModel.displayName message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *renameAction = [UIAlertAction actionWithTitle:@"重命名" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self renameFile];
    }];
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self deleteFile];
    }];
    UIAlertAction *shareAction = [UIAlertAction actionWithTitle:@"共享" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self shareFile];
    }];
    UIAlertAction *copyAction = [UIAlertAction actionWithTitle:@"复制" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self copyFile];
    }];
    UIAlertAction *infoAction = [UIAlertAction actionWithTitle:@"详情" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self infoAction];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:NULL];
    [alVc addAction:renameAction];
    [alVc addAction:deleteAction];
    [alVc addAction:shareAction];
    [alVc addAction:copyAction];
    [alVc addAction:infoAction];
    [alVc addAction:cancelAction];
    [[UIViewController xy_topViewController] presentViewController:alVc animated:YES completion:nil];
}
- (void)infoAction {
    
    [[[UIAlertView alloc] initWithTitle:@"文件详情" message:[self.fileModel description] delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil] show];
}
- (void)renameFile {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"rename" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        NSString *fileName = self.fileModel.filename;
        textField.text = fileName;
        //        [textField setSelectedRange:NSMakeRange(self.fileModel.filename.length-self.fileModel.fileExtension.length, self.fileModel.fileExtension.length)];
        textField.placeholder = @"请输入需要修改的名字";
        [textField addTarget:self action:@selector(alertViewTextFieldtextChange:) forControlEvents:UIControlEventEditingChanged];
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        if ([self.renameNewName containsString:@"/"]) {
            [MBProgressHUD bb_showMessage:@"名称中不符合的字符" delayTime:2.0];
            return;
        }
        
        NSString *oldPath = self.fileModel.path;
        NSString *currentDirectory = [oldPath substringToIndex:oldPath.length-oldPath.lastPathComponent.length];
        NSString *newPath = [currentDirectory stringByAppendingPathComponent:self.renameNewName];
        BOOL res = [[NSFileManager defaultManager] fileExistsAtPath:newPath];
        if (res) {
            [MBProgressHUD bb_showMessage:@"存在同名的文件" delayTime:2.0];
            return;
        }
        NSError *moveError = nil;
        [[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:newPath error:&moveError];
        if (!moveError) {
            [newPath updateFileModificationDateForFilePath];
            [[NSFileManager defaultManager] removeItemAtPath:oldPath error:&moveError];
            NSError *error = nil;
            [self.fileModel reloadFileWithPath:newPath error:&error];
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
    
    if (_constraints.count) {
        [NSLayoutConstraint deactivateConstraints:_constraints];
    }
    
    NSDictionary *viewDict = @{@"iconView": self.iconView, @"titleLabel": self.titleLabel, @"subTitleLabel": self.subTitleLabel, @"optionBtn": self.optionBtn};
    if ([OSFileCollectionViewFlowLayout singleItemOnLine] && [[OSFileCollectionViewFlowLayout singleItemOnLine] isEqual:@(YES)]) {
        self.titleLabel.numberOfLines = 1;
        NSMutableArray *constraints = @[
                                 [NSLayoutConstraint constraintWithItem:self.iconView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:10.0],
                                 [NSLayoutConstraint constraintWithItem:self.iconView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-10.0],
                                 [NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:6.0],
                                 
                                 
                                 [NSLayoutConstraint constraintWithItem:self.subTitleLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-6.0],
                                 [NSLayoutConstraint constraintWithItem:self.subTitleLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.titleLabel attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0],
                                 [NSLayoutConstraint constraintWithItem:self.iconView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.iconView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:6.0],
                                 [NSLayoutConstraint constraintWithItem:self.optionBtn attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]
                                 ].mutableCopy;
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(==10.0)-[iconView]-(==10.0)-[titleLabel]-(10.0)-[optionBtn(==25.0)]-(10.0)-|" options:kNilOptions metrics:nil views:viewDict]];
        _constraints = constraints;
    }
    else {
        self.titleLabel.numberOfLines = 2;
        
    
        NSMutableArray *constraints = @[
                                        [NSLayoutConstraint constraintWithItem:self.iconView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.iconView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0],
                                         [NSLayoutConstraint constraintWithItem:self.optionBtn attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0],
                                         [NSLayoutConstraint constraintWithItem:self.optionBtn attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0],
                                         [NSLayoutConstraint constraintWithItem:self.optionBtn attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:25.0],
                                        [NSLayoutConstraint constraintWithItem:self.subTitleLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-3.0]].mutableCopy;
        NSArray *array = @[[NSLayoutConstraint constraintsWithVisualFormat:@"|-(==30.0)-[iconView]-(==30.0)-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:viewDict],
                           [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(==10.0)-[iconView]-(==20.0)-[titleLabel]" options:kNilOptions metrics:nil views:viewDict],
                           [NSLayoutConstraint constraintsWithVisualFormat:@"|-3-[titleLabel]-3-|" options:kNilOptions metrics:nil views:viewDict],
                           [NSLayoutConstraint constraintsWithVisualFormat:@"|-3-[subTitleLabel]-3-[optionBtn]|" options:kNilOptions metrics:nil views:viewDict]];
        
        [constraints addObjectsFromArray:[array valueForKeyPath:@"@unionOfArrays.self"]];
        _constraints = constraints;
        
    }
    [NSLayoutConstraint activateConstraints:_constraints];
    
//    [self.contentView setNeedsDisplay];
}

- (void)invalidateConstraints {
    [self makeConstraints];
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
            if (@available(iOS 8.2, *)) {
                [label setFont:[UIFont monospacedDigitSystemFontOfSize:13.0 weight:UIFontWeightRegular]];
            }
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
            if (@available(iOS 9.0, *)) {
                [label setFont:[UIFont monospacedDigitSystemFontOfSize:11.0 weight:UIFontWeightRegular]];
            }
        } else {
            [label setFont:[UIFont systemFontOfSize:11.0]];
        }
        _subTitleLabel.numberOfLines = 1;
        _subTitleLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    }
    return _subTitleLabel;
}
@end

