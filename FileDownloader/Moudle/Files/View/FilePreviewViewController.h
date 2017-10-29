//
//  FilePreviewViewController.h
//  FileDownloader
//
//  Created by Swae on 2017/10/29.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FilePreviewViewController : UIViewController {
    UITextView *_textView;
    UIImageView *_imageView;
}

@property (nonatomic, copy) NSString *filePath;

- (instancetype)initWithPath:(NSString *)file;

@end
