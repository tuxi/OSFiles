//
//  OSAuthenticatorHelper.h
//  FileDownloader
//
//  Created by Swae on 2017/10/22.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SmileAuthenticator.h"


FOUNDATION_EXPORT NSString * const OSAuthenticatorBackgroundImageNameKey;

@interface OSAuthenticatorHelper : NSObject

@property (nonatomic, strong, class) OSAuthenticatorHelper *sharedInstance;
@property (nonatomic, copy) NSString *backgroundImageName;

- (void)initAuthenticator;
- (void)applicationDidBecomeActiveWithRemoveCoverImageView;
- (void)applicationWillResignActiveWithShowCoverImageView;
- (void)saveImage:(UIImage *)currentImage withName:(NSString *)imageName;


@end
