//
//  OSProminentSwitch.m
//  OSFileDownloader
//
//  Created by Swae on 2017/10/21.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSProminentSwitch.h"

@implementation OSProminentSwitch

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.layer.cornerRadius = round(0.5*self.bounds.size.height);
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    self.backgroundColor = enabled ? nil : UIColorFromRGB(0xC8CCD1);
    self.tintColor = enabled ? nil : UIColorFromRGB(0xEAECF0);
}
@end
