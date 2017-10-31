
//
//  ApplicationHelper.m
//  FileDownloader
//
//  Created by Swae on 2017/10/31.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "ApplicationHelper.h"
#import "NetworkTypeUtils.h"
#import "OSFileDownloaderManager.h"

@implementation ApplicationHelper

@dynamic helper;

+ (ApplicationHelper *)helper {
    static id _helper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _helper = self.new;
    });
    return _helper;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addNotification];
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    
    _pasteboard = [UIPasteboard generalPasteboard];
}

- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkChange:) name:NetworkTypeChangeNotification object:nil];
}

- (void)networkChange:(NSNotification *)notification {
    
    NetworkType type = [NetworkTypeUtils networkType];
    switch (type) {
        case NetworkTypeWIFI: {
            [[OSFileDownloaderManager sharedInstance] autoDownloadFailure];
            break;
        }
        case NetworkTypeWWAN: {
            [[OSFileDownloaderManager sharedInstance] failureAllDownloadTask];
            break;
        }
        default:
            break;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
