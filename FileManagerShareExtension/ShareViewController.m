//
//  ShareViewController.m
//  FileManagerShareExtension
//
//  Created by Swae on 2017/11/11.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "ShareViewController.h"
#import "OSItemProviderHelper.h"
#import "NSString+OSFile.h"
#import "AppGroupManager.h"
#import <OSFileManager.h>
#import <MBProgressHUD.h>
#import "BrowserViewController.h"
#import "UIViewController+XYExtensions.h"

#define dispatch_main_safe_async(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}

@interface ShareViewController ()

@property (nonatomic, copy) OSShareResultHandler resultHandler;
@property (nonatomic, strong) OSFileManager *fileManager;
@property (nonatomic, strong) MBProgressHUD *hud;

@end

@implementation ShareViewController

- (void)viewDidLoad {
    __weak typeof(&*self) weakSelf = self;
    _resultHandler = ^ {
        __strong typeof(&*weakSelf) self = weakSelf;
        [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
        AudioServicesPlaySystemSound(self.sound);
    };
    
    [super viewDidLoad];
     _sound = 1001;
    self.title = @"我的文件";
    _fileManager = [OSFileManager new];
    self.textView.hidden = YES;
}

// 如果是return No, 那么发送按钮就无法点击, 如果return YES, 那么发送按钮就可以点击
- (BOOL)isContentValid {
    // Do validation of contentText and/or NSExtensionContext attachments here
    return YES;
}

/// 发送按钮的Action事件
- (void)didSelectPost {
   
    NSExtensionItem *input = self.extensionContext.inputItems.firstObject;
    NSExtensionItem *output = [input copy];
    output.attributedContentText = [[NSAttributedString alloc] initWithString:self.contentText attributes:nil];
    
    if (output.attachments.count) {
        NSItemProvider *i = nil;
        for(NSItemProvider *p in output.attachments) {
            if([p hasItemConformingToTypeIdentifier:@"public.url"] && ![p hasItemConformingToTypeIdentifier:@"public.file-url"]) {
                i = p;
                break;
            }
        }
        if(!i) {
            for(NSItemProvider *p in output.attachments) {
                if([p hasItemConformingToTypeIdentifier:@"public.image"]) {
                    i = p;
                    break;
                }
            }
        }
        if(!i)
            i = output.attachments.firstObject;
        
        NSItemProviderCompletionHandler imageHandler = ^(UIImage *item, NSError *error) {
            NSLog(@"Uploading image to imgur");
            if (!error) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
                }];
            }
            NSData *imageData = UIImagePNGRepresentation(item);
            BOOL flag = [imageData writeToFile:[AppGroupManager getAPPGroupSharePath] atomically:YES];
            if (!flag) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    UIAlertController *c = [UIAlertController alertControllerWithTitle:@"分享失败" message:nil preferredStyle:UIAlertControllerStyleAlert];
                    [c addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                        [self cancel];
                        [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
                    }]];
                    [self presentViewController:c animated:YES completion:nil];
                }];
            }
            else {
                self.resultHandler();
            }
        };
        
        NSItemProviderCompletionHandler urlHandler = ^(NSURL *item, NSError *error) {
            if (!item.path.length) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    UIAlertController *c = [UIAlertController alertControllerWithTitle:@"资源无效" message:nil preferredStyle:UIAlertControllerStyleAlert];
                    [c addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                        [self cancel];
                        [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
                    }]];
                    [self presentViewController:c animated:YES completion:nil];
                }];
                return;
            }
            if ([item.scheme.lowercaseString isEqualToString:@"file"]) {
                NSLog(@"%@ %@",self.contentText,item.absoluteString);
                [self copyFiles:@[item.path] toRootDirectory:[AppGroupManager getAPPGroupSharePath] completionHandler:^(void) {
                    if (!error) {
                        self.resultHandler();
                        [[AppGroupManager defaultManager] openAPP:APP_URL_SCHEMES info:@{AppGroupFuncNameKey: @"share", AppGroupFolderPathKey: [AppGroupManager getAPPGroupSharePath]}];
                    }
                    else {
                        NSLog(@"%@", error);
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            UIAlertController *c = [UIAlertController alertControllerWithTitle:@"分享失败" message:nil preferredStyle:UIAlertControllerStyleAlert];
                            [c addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                                [self cancel];
                                [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
                            }]];
                            [self presentViewController:c animated:YES completion:nil];
                        }];
                    }
                }];
                
            }
            else if ([item.scheme.lowercaseString isEqualToString:@"http"] ||
                     [item.scheme.lowercaseString isEqualToString:@"https"]) {
                self.resultHandler();
                [[AppGroupManager defaultManager] openAPP:APP_URL_SCHEMES info:@{AppGroupFuncNameKey: @"url", AppGroupRemoteURLPathKey: item}];
            }
            else {
                [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
            }
            
        };
        
        if ([i hasItemConformingToTypeIdentifier:@"public.url"]) {
            [i loadItemForTypeIdentifier:@"public.url" options:nil completionHandler:urlHandler];
        } else if([i hasItemConformingToTypeIdentifier:@"public.movie"]) {
            [i loadItemForTypeIdentifier:@"public.movie" options:nil completionHandler:urlHandler];
        } else if([i hasItemConformingToTypeIdentifier:@"public.image"]) {
            [i loadItemForTypeIdentifier:@"public.image" options:nil completionHandler:imageHandler];
        } else if([i hasItemConformingToTypeIdentifier:@"public.plain-text"]) {
            self.resultHandler();
        } else {
            NSLog(@"Unknown attachment type: %@", output.attachments.firstObject);
            self.resultHandler();
        }
    } else {
        self.resultHandler();
    }
}

/// 这个方法是用来返回items的一个方法, 而且返回值是数组
- (NSArray *)configurationItems {
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    return @[];
}

/// 当你选择分享的文件展示完的时候就会调用
- (void)presentationAnimationDidFinish {
    
    NSExtensionItem *extensionItem = self.extensionContext.inputItems[0];
    
    NSLog(@"%@", extensionItem);
}

/// copy 文件
- (void)copyFiles:(NSArray<NSString *> *)fileItems
  toRootDirectory:(NSString *)rootPath
completionHandler:(void (^)(void))completion {
    if (!fileItems.count) {
        return;
    }
    [fileItems enumerateObjectsUsingBlock:^(NSString * _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSString *desPath = [rootPath stringByAppendingPathComponent:[path lastPathComponent]];
        if ([desPath isEqualToString:path]) {
            NSLog(@"路径相同");
            dispatch_main_safe_async(^{
                self.hud.label.text = @"路径相同";
                if (completion) {
                    completion();
                }
            });
        }
        else if ([[NSFileManager defaultManager] fileExistsAtPath:desPath]) {
            dispatch_main_safe_async(^{
                self.hud.label.text = @"存在相同文件，正在移除原文件";
            });
            NSError *removeError = nil;
            [[NSFileManager defaultManager] removeItemAtPath:desPath error:&removeError];
            if (removeError) {
                NSLog(@"Error: %@", removeError.localizedDescription);
            }
            
            
        }
    }];
    
    NSMutableArray *hudDetailTextArray = @[].mutableCopy;
    
    void (^hudDetailTextCallBack)(NSString *detailText, NSInteger index) = ^(NSString *detailText, NSInteger index){
        @synchronized (hudDetailTextArray) {
            [hudDetailTextArray replaceObjectAtIndex:index withObject:detailText];
        }
    };
    
    
    /// 当completionCopyNum为0 时 全部拷贝完成
    __block NSInteger completionCopyNum = fileItems.count;
    [fileItems enumerateObjectsUsingBlock:^(NSString *  _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
        [hudDetailTextArray addObject:@(idx).stringValue];
        NSString *desPath = [rootPath stringByAppendingPathComponent:[path lastPathComponent]];
        NSURL *desURL = [NSURL fileURLWithPath:desPath];
        
        void (^ progressBlock)(NSProgress *progress) = ^ (NSProgress *progress) {
            NSString *completionSize = [NSString transformedFileSizeValue:@(progress.completedUnitCount)];
            NSString *totalSize = [NSString transformedFileSizeValue:@(progress.totalUnitCount)];
            NSString *prcent = [NSString percentageString:progress.fractionCompleted];
            NSString *detailText = [NSString stringWithFormat:@"%@  %@/%@", prcent, completionSize, totalSize];
            dispatch_main_safe_async(^{
                hudDetailTextCallBack(detailText, idx);
            });
        };
        
        void (^ completionHandler)(id<OSFileOperation> fileOperation, NSError *error) = ^(id<OSFileOperation> fileOperation, NSError *error) {
            completionCopyNum--;
        };
        NSURL *orgURL = [NSURL fileURLWithPath:path];
        [_fileManager copyItemAtURL:orgURL
                              toURL:desURL
                           progress:progressBlock
                  completionHandler:completionHandler];
    }];
    
    
    
    __weak typeof(self) weakSelf = self;
    
    _fileManager.totalProgressBlock = ^(NSProgress *progress) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.hud.label.text = [NSString stringWithFormat:@"total:%@  %lld/%lld", [NSString percentageString:progress.fractionCompleted], progress.completedUnitCount, progress.totalUnitCount];
        strongSelf.hud.progress = progress.fractionCompleted;
        @synchronized (hudDetailTextArray) {
            NSString *detailStr = [hudDetailTextArray componentsJoinedByString:@",\n"];
            strongSelf.hud.detailsLabel.text = detailStr;
            
        }
    };
    [_fileManager setCurrentOperationsFinishedBlock:^{
        if (completion) {
            completion();
        }
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.hud.label.text = @"分享完成";
        [strongSelf.hud hideAnimated:YES afterDelay:2.0];
        strongSelf.hud = nil;
    }];
}


- (MBProgressHUD *)hud {
    if (!_hud) {
        _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [_hud.button setTitle:NSLocalizedString(@"Cancel", @"HUD cancel button title") forState:UIControlStateNormal];
        _hud.mode = MBProgressHUDModeDeterminate;
        [_hud.button addTarget:self action:@selector(cancelFileOperation:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _hud;
}

- (void)cancelFileOperation:(id)sender {
    [_fileManager cancelAllOperation];
    [self.hud hideAnimated:YES afterDelay:0.5];
    self.hud = nil;
    [self cancel];
    [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
}
@end
