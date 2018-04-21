//
//  OSTransmitDataViewController.h
//  FileDownloader
//
//  Created by Swae on 2017/12/3.
//  Copyright © 2017年 alpface. All rights reserved.
//

#import <UIKit/UIKit.h>
 #import <GCDWebServers/GCDWebUploader.h>

@interface OSTransmitDataViewController : UIViewController

@property (nonatomic, strong, class) OSTransmitDataViewController *sharedInstance;
@property (nonatomic, strong) GCDWebUploader *webServer;

- (void)startWebServer;
- (void)stopWevServer;

@end
