//
//  OSItemProviderHelper.m
//  FileManagerShareExtension
//
//  Created by Swae on 2017/11/11.
//  Copyright © 2017年 alpface. All rights reserved.
//

#import "OSItemProviderHelper.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "OSMimeTypeMap.h"
#import <AddressBook/AddressBook.h>
#import <AVFoundation/AVFoundation.h>
#import "OSPhoneNumberModel.h"

@implementation OSItemProviderHelper

+ (void)itemsForInputItems:(NSArray *)inputItems {
    NSMutableArray *providers = [[NSMutableArray alloc] init];
    
    for (NSExtensionItem *item in inputItems) {
        for (NSItemProvider *provider in item.attachments)
        {
            if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeMovie])
                [providers addObject:provider];
            else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeAudio])
                [providers addObject:provider];
            else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage])
                [providers addObject:provider];
            else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeFileURL])
                [providers addObject:provider];
            else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
                [providers removeAllObjects];
                
                [providers addObject:provider];
                break;
            }
            else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeVCard])
                [providers addObject:provider];
            else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeText])
                [providers addObject:provider];
            else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeData])
                [providers addObject:provider];
        }
    }
    NSLog(@"%@", kUTTypeFileURL);
    NSInteger providerIndex = -1;
    for (NSItemProvider *provider in providers)
    {
        providerIndex++;
        
        if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeAudio]) {
            [self audioItemProvider:provider completionHandler:^(NSMutableDictionary *result, NSError *error) {
                
            }];
        }
        
        else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeMovie]) {
            [self videoItemProvider:provider completionHandler:^(NSURL *url, NSError *error) {
                
            }];
        }
        else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage]) {
            [self imageItemProvider:provider completionHandler:^(id image, NSError *error) {
                
            }];
        }
        else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeFileURL]) {
            
            [self urlItemProvider:provider completionHandler:^(NSURL *url, NSError *error) {
                NSData *data = [[NSData alloc] initWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:nil];
                if (data == nil) {
                    NSString *fileName = [[url pathComponents] lastObject];
                    if (fileName.length == 0)
                        fileName = @"file.bin";
                    NSString *extension = [fileName pathExtension];
                    NSString *mimeType = [OSMimeTypeMap mimeTypeForExtension:[extension lowercaseString]];
                    if (mimeType == nil)
                        mimeType = @"application/octet-stream";
                }
                    
            }];
        }
        
        else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeVCard]) {
            [self vCardItemProvider:provider completionHandler:^(NSURL *url, NSError *error) {
                
            }];
        }
        
        else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeText]) {
            [self textItemProvider:provider completionHandler:^(NSString *text, NSError *error) {
                
            }];
        }
            
        else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
            [self textUrlItemProvider:provider completionHandler:^(NSURL *url, NSError *error) {
                
            }];
        }
        
        else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeData]) {
            [self dataItemProvider:provider completionHandler:^(NSData *data, NSError *error) {
                
            }];
        }
        
    }
    
}

+ (void)dataItemProvider:(NSItemProvider *)itemProvider completionHandler:(void (^)(NSData *data, NSError *error))completionHandler {
    if (!completionHandler) {
        return;
    }
    [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeData options:nil completionHandler:^(NSData *data, NSError *error)
     {
         if (error != nil) {
             completionHandler(nil, error);
         }
         else {
             completionHandler(data, nil);
         }
     }];
    
}

+ (void)imageItemProvider:(NSItemProvider *)itemProvider completionHandler:(void (^)(id image, NSError *error))completionHandler {
    if (!completionHandler) {
        return;
    }
    [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeImage options:nil completionHandler:^(id image, NSError *error)
     {
         if (error != nil) {
             completionHandler(nil, error);
         }
         else {
             completionHandler(image, nil);
         }
     }];
    
}

+ (void)audioItemProvider:(NSItemProvider *)itemProvider completionHandler:(void (^)(NSMutableDictionary *result, NSError *error))completionHandler {
    if (!completionHandler) {
        return;
    }
    [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeAudio options:nil completionHandler:^(NSURL *url, NSError *error) {
         if (error != nil) {
             completionHandler(nil, error);
         }
         else {
             AVAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
             if (asset == nil) {
                 return;
             }
             
             NSString *extension = url.pathExtension;
             NSString *mimeType = [OSMimeTypeMap mimeTypeForExtension:[extension lowercaseString]];
             if (mimeType == nil)
                 mimeType = @"application/octet-stream";
             
             NSString *title = (NSString *)[[AVMetadataItem metadataItemsFromArray:asset.commonMetadata withKey:AVMetadataCommonKeyTitle keySpace:AVMetadataKeySpaceCommon] firstObject];
             NSString *artist = (NSString *)[[AVMetadataItem metadataItemsFromArray:asset.commonMetadata withKey:AVMetadataCommonKeyArtist keySpace:AVMetadataKeySpaceCommon] firstObject];
             
             NSString *software = nil;
             AVMetadataItem *softwareItem = [[AVMetadataItem metadataItemsFromArray:asset.commonMetadata withKey:AVMetadataCommonKeySoftware keySpace:AVMetadataKeySpaceCommon] firstObject];
             if ([softwareItem isKindOfClass:[AVMetadataItem class]] && ([softwareItem.value isKindOfClass:[NSString class]]))
                 software = (NSString *)[softwareItem value];
             
             bool isVoice = [software hasPrefix:@"com.apple.VoiceMemos"];
             
             NSTimeInterval duration =  CMTimeGetSeconds(asset.duration);
             
             NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
             result[@"audio"] = url;
             result[@"mimeType"] = mimeType;
             result[@"duration"] = @(duration);
             result[@"isVoice"] = @(isVoice);
             if (artist.length > 0)
                 result[@"artist"] = artist;
             if (title.length > 0)
                 result[@"title"] = title;
             
             completionHandler(result, nil);
         }
     }];
}


+ (void)videoItemProvider:(NSItemProvider *)itemProvider completionHandler:(void (^)(NSURL *url, NSError *error))completionHandler {
    if (!completionHandler) {
        return;
    }
    [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeMovie options:nil completionHandler:^(NSURL *url, NSError *error)
     {
         if (error != nil) {
             completionHandler(nil, error);
         }
         else {
//             NSString *extension = url.pathExtension;
//             NSString *mimeType = [OSMimeTypeMap mimeTypeForExtension:[extension lowercaseString]];
//             if (mimeType == nil) {
//                 mimeType = @"application/octet-stream";
//             }
             completionHandler(url, nil);
         }
     }];
    
}

+ (void)urlItemProvider:(NSItemProvider *)itemProvider completionHandler:(void (^)(NSURL *url, NSError *error))completionHandler {
    if (!completionHandler) {
        return;
    }
    [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeFileURL options:nil completionHandler:^(NSURL *url, NSError *error)  {
         if (error != nil) {
             completionHandler(nil, error);
         }
         else {
             completionHandler(url, nil);
         }
     }];
    
}

+ (void)textItemProvider:(NSItemProvider *)itemProvider completionHandler:(void (^)(NSString *text, NSError *error))completionHandler {
    if (!completionHandler) {
        return;
    }
    [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeText options:nil completionHandler:^(NSString *text, NSError *error)  {
        if (error != nil) {
            completionHandler(nil, error);
        }
        else {
            completionHandler(text, nil);
        }
    }];
    
}

+ (void)textUrlItemProvider:(NSItemProvider *)itemProvider completionHandler:(void (^)(NSURL *url, NSError *error))completionHandler {
    if (!completionHandler) {
        return;
    }
    [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeURL options:nil completionHandler:^(NSURL *url, NSError *error)  {
        if (error != nil) {
            completionHandler(nil, error);
        }
        else {
            completionHandler(url, nil);
        }
    }];
    
}

+ (void)vCardItemProvider:(NSItemProvider *)itemProvider completionHandler:(void (^)(NSURL *url, NSError *error))completionHandler {
    if (!completionHandler) {
        return;
    }
    [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeURL options:nil completionHandler:^(NSData *vcard, NSError *error)  {
        if (error != nil) {
            completionHandler(nil, error);
        }
        else {
            
            CFDataRef vCardData = CFDataCreate(NULL, vcard.bytes, vcard.length);
            ABAddressBookRef book = ABAddressBookCreate();
            ABRecordRef defaultSource = ABAddressBookCopyDefaultSource(book);
            CFArrayRef vCardPeople = ABPersonCreatePeopleInSourceWithVCardRepresentation(defaultSource, vCardData);
            CFIndex index = 0;
            ABRecordRef person = CFArrayGetValueAtIndex(vCardPeople, index);
            
            NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
            NSString *lastName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
            
            if (firstName.length == 0 && lastName.length == 0)
                lastName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonOrganizationProperty);
            
            ABMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
            
            NSInteger phoneCount = (phones == NULL) ? 0 : ABMultiValueGetCount(phones);
            NSMutableArray *personPhones = [[NSMutableArray alloc] initWithCapacity:phoneCount];
            
            for (CFIndex i = 0; i < phoneCount; i++)
            {
                NSString *number = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phones, i);
                NSString *label = nil;
                
                CFStringRef valueLabel = ABMultiValueCopyLabelAtIndex(phones, i);
                if (valueLabel != NULL)
                {
                    label = (__bridge_transfer NSString *)ABAddressBookCopyLocalizedLabel(valueLabel);
                    CFRelease(valueLabel);
                }
                
                if (number.length != 0)
                {
                    OSPhoneNumberModel *phoneNumber = [[OSPhoneNumberModel alloc] initWithPhoneNumber:number label:label];
                    [personPhones addObject:phoneNumber];
                }
            }
            if (phones != NULL)
                CFRelease(phones);
            
            OSContactModel *contact = [[OSContactModel alloc] initWithFirstName:firstName lastName:lastName phoneNumbers:personPhones];
            
            completionHandler(contact, nil);
        }
    }];
    
}


@end
