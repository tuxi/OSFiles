//
//  OSPhoneNumberModel.h
//  FileManagerShareExtension
//
//  Created by Swae on 2017/11/11.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSPhoneNumberModel : NSObject

@property (nonatomic, strong, readonly) NSString *phoneNumber;
@property (nonatomic, strong, readonly) NSString *displayPhoneNumber;

@property (nonatomic, strong, readonly) NSString *label;

- (instancetype)initWithPhoneNumber:(NSString *)string label:(NSString *)label;

@end

@interface OSContactModel : NSObject

@property (nonatomic, strong, readonly) NSString *firstName;
@property (nonatomic, strong, readonly) NSString *lastName;

@property (nonatomic, strong, readonly) NSArray *phoneNumbers;

- (instancetype)initWithFirstName:(NSString *)firstName lastName:(NSString *)lastName phoneNumbers:(NSArray *)phoneNumbers;

@end
