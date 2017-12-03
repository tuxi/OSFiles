//
//  OSTransmitDataViewController.m
//  FileDownloader
//
//  Created by Swae on 2017/12/3.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSTransmitDataViewController.h"
#import "SJXCSMIPHelper.h"

@interface OSTransmitDataViewController () <GCDWebUploaderDelegate>

@property (weak, nonatomic) IBOutlet UIView *noConnectionView;
@property (weak, nonatomic) IBOutlet UILabel *noConnectionTitleLabel;
@property (weak, nonatomic) IBOutlet UIView *connectionView;
@property (weak, nonatomic) IBOutlet UILabel *connectionIpAddressLabel;
@property (weak, nonatomic) IBOutlet UILabel *connectionTitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *connectionViewImageView;

@end

@implementation OSTransmitDataViewController

@dynamic sharedInstance;

+ (OSTransmitDataViewController *)sharedInstance {
    static id _instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = self.new;
    });
    return _instance;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.noConnectionView.hidden = NO;
    self.connectionView.hidden = YES;
//    self.noConnectionTitleLabel.text = @"正在检测连接状态...";
    self.connectionTitleLabel.text = @"请确保电脑和手机处于同一WiFi下，\n在电脑浏览器地址输入：";
    self.navigationItem.title = @"WiFi无线文件传输";
    UIColor *blueColor = [UIColor colorWithRed:0/255.0 green:91/255.0 blue:185/255.0 alpha:0.8];
    self.connectionViewImageView.image = [[UIImage imageNamed:@"WiFi_2"] xy_changeImageColorWithColor:blueColor];
    self.connectionIpAddressLabel.textColor = blueColor;
    
    // 默认关闭
//    [self startWebServer];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"开启" style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonItemAction:)];
}

//- (void)viewDidDisappear:(BOOL)animated {
//    [super viewDidDisappear:animated];
//    [self stopWevServer];
//}
//
//- (void)viewDidAppear:(BOOL)animated {
//    [super viewDidAppear:animated];
//    [self startWebServer];
//}

- (void)rightBarButtonItemAction:(UIBarButtonItem *)item {
    if ([item.title isEqualToString:@"开启"]) {
        [self startWebServer];
    }
    else {
        [self stopWevServer];
    }
}

#pragma mark - <GCDWebUploaderDelegate>
- (void)webUploader:(GCDWebUploader *)uploader didUploadFileAtPath:(NSString *)path {
    [self.view bb_showMessage:[NSString stringWithFormat:@"已通过浏览器成功传输文件[%@]", path.lastPathComponent]];
}

- (void)webUploader:(GCDWebUploader *)uploader didMoveItemFromPath:(NSString *)fromPath toPath:(NSString *)toPath {
    
}

- (void)webUploader:(GCDWebUploader *)uploader didDeleteItemAtPath:(NSString *)path {
    [self.view bb_showMessage:[NSString stringWithFormat:@"已通过浏览器成功删除文件[%@]", path.lastPathComponent]];
}

- (void)webUploader:(GCDWebUploader *)uploader didCreateDirectoryAtPath:(NSString *)path {
    [self.view bb_showMessage:[NSString stringWithFormat:@"已通过浏览器成功创建目录[%@]", path.lastPathComponent]];
}

- (GCDWebUploader *)webServer {
    if (!_webServer) {
        // 文件存储位置
        NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        // 创建webServer，设置根目录
        _webServer = [[GCDWebUploader alloc] initWithUploadDirectory:documentsPath];
        // 设置代理
        _webServer.delegate = self;
        _webServer.allowHiddenItems = YES;
        
        // 限制文件上传类型
//        _webServer.allowedFileExtensions = @[@"doc", @"docx", @"xls", @"xlsx", @"txt", @"pdf"];
        // 设置网页标题
        _webServer.title = @"文件浏览 - 无线传输";
        // 设置展示在网页上的文字
        _webServer.prologue = @"拖动文件到本窗口或者使用 \"上传文件…\" 按钮来上传新文件。";
        // 设置展示在网页上的文字(结尾)
        _webServer.epilogue = @"文件浏览 by Ossey";
    }
    return _webServer;
}

- (void)startWebServer {
    // 开启
    if ([self.webServer start]) {
        [self updateViewsByInvalid:NO];
    } else {
        // 当已经处于开启状态时，再调用start会返回NO，所以这里先关闭再重新开启
        [self stopWevServer];
        if ([self.webServer start]) {
            [self updateViewsByInvalid:NO];
        } else {
            [self updateViewsByInvalid:YES];
        }
    }
}

- (void)stopWevServer {
    if (_webServer) {
        [self.webServer stop];
        self.webServer = nil;
        [self updateViewsByInvalid:YES];
    }
}

// 根据webServer是否开启，更新UI
- (void)updateViewsByInvalid:(BOOL)webServerInvalid {
    if (!webServerInvalid) {
        self.noConnectionView.hidden = YES;
        self.connectionView.hidden = NO;
        NSString *ipString = [SJXCSMIPHelper deviceIPAdress];
        NSLog(@"ip地址为：%@", ipString);
        NSUInteger port = self.webServer.port;
        NSLog(@"开启监听的端口为：%zd", port);
        self.connectionIpAddressLabel.text = [NSString stringWithFormat:@"http://%@", ipString];
        self.navigationItem.rightBarButtonItem.title = @"关闭";
        [MBProgressHUD bb_showMessage:@"无线传输已开启" delayTime:1.0];
    }
    else {
        self.noConnectionView.hidden = NO;
        self.connectionView.hidden = YES;
        self.noConnectionTitleLabel.text = @"无线传输已关闭，你可以点击[开启]使用无线传输.";
        self.navigationItem.rightBarButtonItem.title = @"开启";
        [MBProgressHUD bb_showMessage:@"无线传输已关闭" delayTime:1.0];
    }
}

@end
