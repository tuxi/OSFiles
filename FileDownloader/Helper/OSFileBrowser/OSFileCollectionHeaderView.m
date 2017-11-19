//
//  OSFileCollectionHeaderView.m
//  FileDownloader
//
//  Created by Swae on 2017/11/19.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileCollectionHeaderView.h"

NSString * const OSFileCollectionHeaderViewDefaultIdentifier = @"UICollectionReusableView";

@implementation OSFileCollectionHeaderView

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [super touchesBegan:touches withEvent:event];
    
    OSFileCollectionLayoutStyle style = OSFileCollectionLayoutStyleMultipleItemOnLine;
    if ([[OSFileCollectionViewFlowLayout singleItemOnLine] isEqual:@(YES)]) {
        style = OSFileCollectionLayoutStyleSingleItemOnLine;
        [OSFileCollectionViewFlowLayout setSingleItemOnLine:@(NO)];
    }
    else {
        [OSFileCollectionViewFlowLayout setSingleItemOnLine:@(YES)];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(fileCollectionHeaderView:reLayoutStyle:)]) {
        [self.delegate fileCollectionHeaderView:self reLayoutStyle:style];
    }
}

@end
