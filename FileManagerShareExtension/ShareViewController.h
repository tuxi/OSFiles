//
//  ShareViewController.h
//  FileManagerShareExtension
//
//  Created by Swae on 2017/11/11.
//  Copyright © 2017年 alpface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import <AudioToolbox/AudioToolbox.h>

typedef void (^OSShareResultHandler)(void);

@interface ShareViewController : SLComposeServiceViewController

@property SystemSoundID sound;

@end
