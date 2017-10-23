//
//  BookmarkSectionTableViewCell.m
//  WebBrowser
//
//  Created by Null on 2017/5/9.
//  Copyright © 2017年 Null. All rights reserved.
//

#import "BookmarkSectionTableViewCell.h"

@implementation BookmarkSectionTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.contentView.backgroundColor = UIColorFromRGB(0xF7F7F7);
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated{
    [super setEditing:editing animated:animated];
    
    self.showsReorderControl = editing;
}

@end
