//
//  DownloadsViewController.m
//  FileDownloader
//
//  Created by Ossey on 2017/6/10.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "DownloadsViewController.h"

@interface DownloadsViewController ()

@end

@implementation DownloadsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ Config NoDataPlaceholderExtend ~~~~~~~~~~~~~~~~~~~~~~~

- (NSAttributedString *)titleAttributedStringForNoDataPlaceholder {
    
    NSString *text = @"当前无下载任务";
    
    UIFont *font = nil;
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_4) {
        font = [UIFont monospacedDigitSystemFontOfSize:18.0 weight:UIFontWeightRegular];
    } else {
        font = [UIFont boldSystemFontOfSize:18.0];
    }
    UIColor *textColor = [UIColor redColor];
    
    NSMutableDictionary *attributeDict = [NSMutableDictionary dictionaryWithCapacity:0];
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.lineBreakMode = NSLineBreakByWordWrapping;
    style.alignment = NSTextAlignmentCenter;
    
    [attributeDict setObject:font forKey:NSFontAttributeName];
    [attributeDict setObject:textColor forKey:NSForegroundColorAttributeName];
    [attributeDict setObject:style forKey:NSParagraphStyleAttributeName];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:attributeDict];
    
    return attributedString;
    
}

- (NSAttributedString *)reloadbuttonTitleAttributedStringForNoDataPlaceholder {
    
    UIFont *font = nil;
    
    NSString *text = @"输入URL";
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_4) {
        font = [UIFont monospacedDigitSystemFontOfSize:15.0 weight:UIFontWeightRegular];
    } else {
        font = [UIFont boldSystemFontOfSize:15.0];
    }
    UIColor *textColor = [UIColor blackColor];
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    if (font) [attributes setObject:font forKey:NSFontAttributeName];
    if (textColor) [attributes setObject:textColor forKey:NSForegroundColorAttributeName];
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)noDataPlaceholderImageWithIsLoading:(BOOL)isLoading {
    if (isLoading) {
        return [super noDataPlaceholderImageWithIsLoading:isLoading];
    } else {
        UIImage *image = [UIImage imageNamed:@"downloadIcon"];
        return image;
    }
}


@end
