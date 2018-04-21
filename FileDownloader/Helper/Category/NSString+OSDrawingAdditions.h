//
//  NSString+OSDrawingAdditions.h
//  FileDownloader
//
//  Created by Swae on 2017/10/30.
//  Copyright © 2017年 alpface. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (OSDrawingAdditions)

- (CGSize)sizeWithMaxSize:(CGSize)maxSize font:(UIFont*)font;

@end
