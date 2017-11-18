//
//  OSFile.m
//  FileBrowser
//
//  Created by xiaoyuan on 05/08/2014.
//  Copyright © 2014 xiaoyuan. All rights reserved.
//

#import "OSFile.h"
#import "NSString+OSFile.h"
#include <sys/stat.h>
#import "NSDate+ESUtilities.h"
#import "OSMimeTypeMap.h"

@implementation OSFile
@synthesize isDirectory                 = _isDirectory;
@synthesize isRegularFile               = _isRegularFile;
@synthesize isSymbolicLink              = _isSymbolicLink;
@synthesize isSocket                    = _isSocket;
@synthesize isCharacterSpecial          = _isCharacterSpecial;
@synthesize isBlockSpecial              = _isBlockSpecial;
@synthesize isUnknown                   = _isUnknown;
@synthesize isImmutable                 = _isImmutable;
@synthesize isAppendOnly                = _isAppendOnly;
@synthesize isBusy                      = _isBusy;
@synthesize isImage                     = _isImage;
@synthesize isAudio                     = _isAudio;
@synthesize isVideo                     = _isVideo;
@synthesize isArchive                   = _isArchive;
@synthesize isWindows                   = _isWindows;
@synthesize flags                       = _flags;
@synthesize extensionIsHidden           = _extensionIsHidden;
@synthesize isReadable                  = _isReadable;
@synthesize isWriteable                 = _isWriteable;
@synthesize isExecutable                = _isExecutable;
@synthesize size                        = _size;
@synthesize referenceCount              = _referenceCount;
@synthesize deviceIdentifier            = _deviceIdentifier;
@synthesize ownerID                     = _ownerID;
@synthesize groupID                     = _groupID;
@synthesize permissions                 = _permissions;
@synthesize octalPermissions            = _octalPermissions;
@synthesize systemNumber                = _systemNumber;
@synthesize systemFileNumber            = _systemFileNumber;
@synthesize HFSCreatorCode              = _HFSCreatorCode;
@synthesize HFSTypeCode                 = _HFSTypeCode;
@synthesize numberOfSubFiles            = _numberOfSubFiles;
@synthesize path                        = _path;
@synthesize filename                    = _filename;
@synthesize displayName                 = _displayName;
@synthesize fileExtension               = _fileExtension;
@synthesize parentDirectoryPath         = _parentDirectoryPath;
@synthesize type                        = _type;
@synthesize owner                       = _owner;
@synthesize group                       = _group;
@synthesize humanReadableSize           = _humanReadableSize;
@synthesize humanReadablePermissions    = _humanReadablePermissions;
@synthesize creationDate                = _creationDate;
@synthesize modificationDate            = _modificationDate;
//@synthesize icon                        = _icon;
@synthesize targetFile                  = _targetFile;
@synthesize hideDisplayFiles            = _hideDisplayFiles;
@synthesize mimeType                    = _mimeType;

+ (instancetype)fileWithPath:(NSString *)filePath {
    return [self fileWithPath:filePath error:NULL];
}

+ (instancetype)fileWithPath:(NSString *)filePath error:(NSError *__autoreleasing *)error {
    return [self fileWithPath:filePath hideDisplayFiles:YES error:error];
}

+ (instancetype)fileWithPath:(NSString *)filePath hideDisplayFiles:(BOOL)hideDisplayFiles error:(NSError *__autoreleasing *)error {
    return [[self alloc] initWithPath:filePath hideDisplayFiles:hideDisplayFiles error:error];
}

- (instancetype)initWithPath:(NSString *)filePath {
    return [self initWithPath:filePath error:NULL];
}

- (instancetype)initWithPath:(NSString *)filePath error:(NSError *__autoreleasing *)error {
    return [self initWithPath:filePath hideDisplayFiles:YES error:error];
}

- (instancetype)initWithPath:(NSString *)filePath hideDisplayFiles:(BOOL)hideDisplayFiles error:(NSError *__autoreleasing *)error {
    
    if (self = [super init]) {
        _hideDisplayFiles = hideDisplayFiles;
        _path        = [filePath copy];
        _fileManager = [NSFileManager defaultManager];
        [self reloadFileWithError:error];
    }
    
    return self;
}

- (BOOL)reloadFile {
    return [self reloadFileWithError:NULL];
}

- (BOOL)reloadFileWithPath:(NSString *)filePath error:(NSError *__autoreleasing *)error {
    _path        = [filePath copy];
   return [self reloadFileWithError:error];
}

- (BOOL)reloadFileWithError:(NSError *__autoreleasing *)error {
    NSError  *e = nil;
    NSString *symLinkTarget = nil;
    if ([_fileManager fileExistsAtPath: _path isDirectory:&_isDirectory] == NO) {
        return NO;
    }
    _attributes = [_fileManager attributesOfItemAtPath: _path error: &e];
    
    if (_attributes == nil || e != nil) {
        if (error) {
            *error = e;
        }
        return NO;
    }
    
    [self getPathInfos];
    [self getFileType];
    [self getOwnership];
    [self getPermissions];
    [self getFlags];
    [self getSize];
    [self getDates];
    [self getFileSystemAttributes];
    
    NSArray *(^processFileBlock)(NSString *path) = ^(NSString *path) {
        /*
         系统中某些文件没有权限加载
         Error Domain=NSCocoaErrorDomain Code=257 "The file “var” couldn’t be opened because you don’t have permission to view it." UserInfo={NSFilePath=/var, NSUserStringVariant=(
         Folder
        ), NSUnderlyingError=0x1c8044c20 {Error Domain=NSPOSIXErrorDomain Code=1 "Operation not permitted"}}
         */
        NSArray *array = nil;
        if ([path isEqualToString:@"/System"]) {
            array = @[@"Library"];
        }
        
        if ([path isEqualToString:@"/Library"]) {
            array = @[@"Preferences"];
        }
        
        if ([path isEqualToString:@"/var"]) {
            array = @[@"mobile"];
        }
        
        if ([path isEqualToString:@"/usr"]) {
            array = @[@"lib", @"libexec", @"bin"];
        }
        return array;
    };
    
    if(_isDirectory == YES) {
        _subFiles = [_fileManager contentsOfDirectoryAtPath: _path error: &e];
        if (e) {
            _subFiles = processFileBlock(_path);
            if (error) {
                *error = e;
            }
        }
        else {
            if (_hideDisplayFiles) {
                [self removeHideFiles];
            }
        }
    }
    
    if(_isSymbolicLink == YES) {
        symLinkTarget = [_fileManager destinationOfSymbolicLinkAtPath: _path error: &e];
        if (error) {
            *error = e;
        }
        
        if([symLinkTarget characterAtIndex: 0] != '/')
        {
            if([_parentDirectoryPath characterAtIndex: [_parentDirectoryPath length] - 1] == '/')
            {
                symLinkTarget = [_parentDirectoryPath stringByAppendingString: symLinkTarget];
            }
            else
            {
                symLinkTarget = [NSString stringWithFormat: @"%@/%@", _parentDirectoryPath, symLinkTarget];
            }
        }
        
        _targetFile = [[OSFile alloc] initWithPath:symLinkTarget];
    }
    
    [self getSubTypes];
    [self sortedSubFiles];
    //        [self getIcon];
    return YES;
}

- (void)removeHideFiles {
    if (!self.subFiles.count) {
        return;
    }
    NSMutableArray *tempFiles = [self.subFiles mutableCopy];
    NSIndexSet *indexSet = [tempFiles indexesOfObjectsPassingTest:^BOOL(NSString * _Nonnull fileName, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([fileName isKindOfClass:[NSString class]]) {
            return [fileName hasPrefix:@"."];
        }
        return NO;
    }];
    [tempFiles removeObjectsAtIndexes:indexSet];
    _subFiles = tempFiles.copy;
}

- (NSUInteger)numberOfSubFiles {
    return _subFiles.count;
}

#pragma mark *** Private methods ***
- (void)getPathInfos
{
    _filename            = [[NSString alloc] initWithString: [_path lastPathComponent]];
    _displayName         = [[NSString alloc] initWithString: [_fileManager displayNameAtPath: _path]];
    _fileExtension       = [[NSString alloc] initWithString: [_path pathExtension]];
    if ([_fileExtension containsString:@"?"]) {
        _fileExtension = [_fileExtension substringWithRange:NSRangeFromString(@"?")];
    }
    _parentDirectoryPath = [[NSString alloc] initWithString: [_path stringByDeletingLastPathComponent]];
    if (_fileExtension.length) {
        _mimeType = [OSMimeTypeMap mimeTypeForExtension:_fileExtension];
    }
}

- (void)getFileType
{
    if (!_isDirectory) {
        // mark: _attributes 中获取的有时不是对的，所以如果_isDirectory是YES，就不再获取了
        _isDirectory        = [_attributes objectForKey: NSFileType] == NSFileTypeDirectory;
    }
    _isRegularFile      = [_attributes objectForKey: NSFileType] == NSFileTypeRegular;
    _isSymbolicLink     = [_attributes objectForKey: NSFileType] == NSFileTypeSymbolicLink;
    _isSocket           = [_attributes objectForKey: NSFileType] == NSFileTypeSocket;
    _isCharacterSpecial = [_attributes objectForKey: NSFileType] == NSFileTypeCharacterSpecial;
    _isBlockSpecial     = [_attributes objectForKey: NSFileType] == NSFileTypeBlockSpecial;
    _isUnknown          = [_attributes objectForKey: NSFileType] == NSFileTypeUnknown;
    
    if(_isDirectory == NO && _isRegularFile == NO && _isSymbolicLink == NO && _isSocket == NO && _isCharacterSpecial == NO && _isBlockSpecial == NO)
    {
        _isUnknown = YES;
        _type      = [[NSString alloc] initWithString: NSFileTypeUnknown];
    }
    else
    {
        _type = [[NSString alloc] initWithString: [_attributes objectForKey: NSFileType]];
    }
    
}

- (void)getOwnership
{
    _ownerID = ([_attributes objectForKey: NSFileOwnerAccountID] == nil) ? 0                                          : (NSUInteger)[[_attributes objectForKey: NSFileOwnerAccountID] integerValue];
    _groupID = ([_attributes objectForKey: NSFileGroupOwnerAccountID]   == nil) ? 0                                          : (NSUInteger)[[_attributes objectForKey: NSFileGroupOwnerAccountID] integerValue];
    _owner  = ([_attributes objectForKey: NSFileOwnerAccountName]  == nil) ? @"" : [[_attributes objectForKey: NSFileOwnerAccountName] copy];
    _group   = ([_attributes objectForKey: NSFileGroupOwnerAccountName] == nil) ? @"" : [[_attributes objectForKey: NSFileOwnerAccountName] copy];
}

- (void)getPermissions {
    NSUInteger i;
    NSUInteger u;
    NSUInteger g;
    NSUInteger o;
    NSUInteger uid;
    NSUInteger gid;
    NSUInteger decimalPerms;
    NSNumber * perms;
    NSString * humanPerms;
    
    uid   = getuid();
    gid   = getgid();
    perms = [_attributes objectForKey: NSFilePosixPermissions];
    
    if(perms == nil)
    {
        _permissions              = 0;
        _octalPermissions         = 0;
        _humanReadablePermissions = @"--- --- ---";
        _isReadable               = NO;
        _isWriteable              = NO;
        _isExecutable             = NO;
        
        return;
    }
    
    _permissions      = (NSUInteger)[perms integerValue];
    decimalPerms      = _permissions;
    u                 = decimalPerms / 64;
    g                 = (decimalPerms - (64 * u)) / 8;
    o                 = (decimalPerms - (64 * u)) - (8 * g);
    _octalPermissions = (u * 100) + (g * 10) + o;
    humanPerms        = @"";
    
    for(i = 0; i < 3; i++)
    {
        humanPerms   = [[NSString stringWithFormat: @"%@%@%@ ", (decimalPerms & 4) ? @"r" : @"-", (decimalPerms & 2) ? @"w" : @"-", (decimalPerms & 1) ? @"x" : @"-"] stringByAppendingString: humanPerms];
        decimalPerms = decimalPerms >> 3;
    }
    
    _humanReadablePermissions = [[NSString alloc] initWithString: humanPerms];
    
    if(_ownerID == uid)
    {
        _isReadable   = (u & 4) ? YES : NO;
        _isWriteable  = (u & 2) ? YES : NO;
        _isExecutable = (u & 1) ? YES : NO;
        
    }
    else if(_groupID == gid)
    {
        _isReadable   = (g & 4) ? YES : NO;
        _isWriteable  = (g & 2) ? YES : NO;
        _isExecutable = (g & 1) ? YES : NO;
    }
    else
    {
        _isReadable   = (o & 4) ? YES : NO;
        _isWriteable  = (o & 2) ? YES : NO;
        _isExecutable = (o & 1) ? YES : NO;
    }
    
    if(_isReadable == NO && [_fileManager isReadableFileAtPath: _path] == YES)
    {
        _isReadable = YES;
    }
    
    if(_isWriteable == NO && [_fileManager isWritableFileAtPath: _path] == YES)
    {
        _isWriteable = YES;
    }
    
    if(_isExecutable == NO && [_fileManager isExecutableFileAtPath: _path] == YES)
    {
        _isExecutable = YES;
    }
}

- (void)getFlags
{
    int err;
    struct stat fileStat;
    
    _isImmutable       = ([_attributes objectForKey: NSFileImmutable]       == nil) ? NO : [[_attributes objectForKey: NSFileImmutable]       boolValue];
    _isAppendOnly      = ([_attributes objectForKey: NSFileAppendOnly]      == nil) ? NO : [[_attributes objectForKey: NSFileAppendOnly]      boolValue];
    _isBusy            = ([_attributes objectForKey: NSFileBusy]            == nil) ? NO : [[_attributes objectForKey: NSFileBusy]            boolValue];
    _extensionIsHidden = ([_attributes objectForKey: NSFileExtensionHidden] == nil) ? NO : [[_attributes objectForKey: NSFileExtensionHidden] boolValue];
    
    err = stat([_path cStringUsingEncoding: NSUTF8StringEncoding], &fileStat);
    
    if(err != 0)
    {
        return;
    }
    
    if(fileStat.st_flags & SF_ARCHIVED)   { _flags |= OSFileFlagsArchived;            }
    if(fileStat.st_flags & UF_HIDDEN)     { _flags |= OSFileFlagsHidden;              }
    if(fileStat.st_flags & UF_NODUMP)     { _flags |= OSFileFlagsNoDump;              }
    if(fileStat.st_flags & UF_OPAQUE)     { _flags |= OSFileFlagsOpaque;              }
    if(fileStat.st_flags & SF_APPEND)     { _flags |= OSFileFlagsSystemAppendOnly;    }
    if(fileStat.st_flags & SF_IMMUTABLE)  { _flags |= OSFileFlagsSystemImmutable;     }
    if(fileStat.st_flags & UF_APPEND)     { _flags |= OSFileFlagsUserAppendOnly;      }
    if(fileStat.st_flags & UF_IMMUTABLE)  { _flags |= OSFileFlagsUserImmutable;       }
}

- (void)getSize
{
    _size              = ([_attributes objectForKey: NSFileSize] == nil) ? 0 : (NSUInteger)[[_attributes objectForKey: NSFileSize] integerValue];
    _humanReadableSize = [NSString stringForSize: (uint64_t)_size];
}

- (void)getDates
{
    _creationDate     = ([_attributes objectForKey: NSFileCreationDate]     == nil) ? [NSDate date] : [_attributes objectForKey: NSFileCreationDate];
    _modificationDate = ([_attributes objectForKey: NSFileModificationDate] == nil) ? [NSDate date] : [_attributes objectForKey: NSFileModificationDate];
}

- (void)getFileSystemAttributes
{
    _referenceCount   = ([_attributes objectForKey: NSFileReferenceCount]   == nil) ? 0 : (NSUInteger)[[_attributes objectForKey: NSFileReferenceCount]   integerValue];
    _deviceIdentifier = ([_attributes objectForKey: NSFileDeviceIdentifier] == nil) ? 0 : (NSUInteger)[[_attributes objectForKey: NSFileDeviceIdentifier] integerValue];
    _systemNumber     = ([_attributes objectForKey: NSFileSystemNumber]     == nil) ? 0 : (NSUInteger)[[_attributes objectForKey: NSFileSystemNumber]     integerValue];
    _systemFileNumber = ([_attributes objectForKey: NSFileSystemFileNumber] == nil) ? 0 : (NSUInteger)[[_attributes objectForKey: NSFileSystemFileNumber] integerValue];
    _HFSCreatorCode   = ([_attributes objectForKey: NSFileHFSCreatorCode]   == nil) ? 0 : (NSUInteger)[[_attributes objectForKey: NSFileHFSCreatorCode]   integerValue];
    _HFSTypeCode      = ([_attributes objectForKey: NSFileHFSTypeCode]      == nil) ? 0 : (NSUInteger)[[_attributes objectForKey: NSFileHFSTypeCode]      integerValue];
}

- (void)sortedSubFiles {
    _subFiles =  [_subFiles sortedArrayWithOptions:NSSortConcurrent usingComparator:^NSComparisonResult(NSString* file1, NSString* file2) {
        NSString *newPath1 = [self.path stringByAppendingPathComponent:file1];
        NSString *newPath2 = [self.path stringByAppendingPathComponent:file2];
        
        BOOL isDirectory1, isDirectory2;
        [[NSFileManager defaultManager] fileExistsAtPath:newPath1 isDirectory:&isDirectory1];
        [[NSFileManager defaultManager] fileExistsAtPath:newPath2 isDirectory:&isDirectory2];
        
        if (isDirectory1 && !isDirectory2) {
            return NSOrderedAscending;
        }
        
        return  NSOrderedDescending;
    }];
}

- (void)getSubTypes {
    OSFile * infos;
    
    infos = (_isSymbolicLink) ? _targetFile : self;
    
    if
        (
         infos.isRegularFile &&
         ([[infos.fileExtension lowercaseString] isEqualToString: @"mp3"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"aac"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"aifc"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"aiff"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"caf"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"m4a"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"m4r"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"3gp"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"wav"])
        )
    {
        _isAudio = YES;
    }
    
    if
        (
         infos.isRegularFile &&
         ([[infos.fileExtension lowercaseString] isEqualToString: @"m4v"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"mov"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"avi"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"mpg"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"mp4"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"mov"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"wmv"])
        )
    {
        _isVideo = YES;
    }
    
    if
        (
         infos.isRegularFile &&
         ([[infos.fileExtension lowercaseString] isEqualToString: @"png"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"tif"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"tiff"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"jpg"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"jpeg"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"gif"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"bmp"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"bmpf"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"ico"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"cur"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"xbm"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"webp"])
        )
    {
        _isImage = YES;
    }
    if
        (
         infos.isRegularFile &&
         ([[infos.fileExtension lowercaseString] isEqualToString: @"zip"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"rar"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"7zf"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"tar"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"tgz"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"tbz"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"dmg"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"app"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"ipa"])
        )
    {
        _isArchive = YES;
    }
    
    if
        (
         infos.isRegularFile &&
         ([[infos.fileExtension lowercaseString] isEqualToString: @"exe"])
        )
    {
        _isWindows = YES;
    }
}

- (UIImage *)iconByAddingEmblemsToImage: (UIImage *)baseIcon
{
    CGRect       frame;
    CGContextRef context;
    UIImage    * emblem;
    UIImage    * finalIcon;
    OSFile     * infos;
    
    if([[UIScreen mainScreen] scale] == 2)
    {
        UIGraphicsBeginImageContext(CGSizeMake(64, 64));
    }
    else
    {
        UIGraphicsBeginImageContext(CGSizeMake(32, 32));
    }
    
    infos   = (_isSymbolicLink) ? _targetFile : self;
    context = UIGraphicsGetCurrentContext();
    
    if([[UIScreen mainScreen] scale] == 2)
    {
        frame = CGRectMake(32, -64, 32, 32);
    }
    else
    {
        frame = CGRectMake(16, -32, 16, 16);
    }
    
    CGContextScaleCTM(context, 1, -1);
    
    if([[UIScreen mainScreen] scale] == 2)
    {
        CGContextDrawImage(context, CGRectMake(0, -64, 64, 64), baseIcon.CGImage);
    }
    else
    {
        CGContextDrawImage(context, CGRectMake(0, -32, 32, 32), baseIcon.CGImage);
    }
    
    if
        (
         infos.isDirectory &&
         ([infos.filename isEqualToString: @"AppStore.app"]
          || [infos.filename isEqualToString: @"Calculator.app"]
          || [infos.filename isEqualToString: @"Maps.app"]
          || [infos.filename isEqualToString: @"MobileAddressBook.app"]
          || [infos.filename isEqualToString: @"MobileCal.app"]
          || [infos.filename isEqualToString: @"MobileMail.app"]
          || [infos.filename isEqualToString: @"MobileNotes.app"]
          || [infos.filename isEqualToString: @"MobileMusicPlayer.app"]
          || [infos.filename isEqualToString: @"MobileSafari.app"]
          || [infos.filename isEqualToString: @"MobileSlideShow.app"]
          || [infos.filename isEqualToString: @"MobileSMS.app"]
          || [infos.filename isEqualToString: @"MobileStore.app"]
          || [infos.filename isEqualToString: @"MobileTimer.app"]
          || [infos.filename isEqualToString: @"MobileNotes.app"]
          || [infos.filename isEqualToString: @"Preferences.app"]
          || [infos.filename isEqualToString: @"Stocks.app"]
          || [infos.filename isEqualToString: @"VoiceMemos.app"]
          || [infos.filename isEqualToString: @"Stocks.app"]
          || [infos.filename isEqualToString: @"Weather.app"]
          || [infos.filename isEqualToString: @"Web.app"]
          || [infos.filename isEqualToString: @"YouTube.app"])
        )
    {
        emblem = [UIImage imageNamed: [NSString stringWithFormat: @"App-%@.png", infos.filename]];
        
        if([[UIScreen mainScreen] scale] == 2)
        {
            CGContextDrawImage(context, CGRectMake(8, -64, 48, 48), emblem.CGImage);
        }
        else
        {
            CGContextDrawImage(context, CGRectMake(4, -32, 24, 24), emblem.CGImage);
        }
    }
    else if
        (
         infos.isDirectory &&
         ([infos.filename isEqualToString: @"AddressBook"]
          || [infos.filename isEqualToString: @"Applications"]
          || [infos.filename isEqualToString: @"Application Support"]
          || [infos.filename isEqualToString: @"Audio"]
          || [infos.filename isEqualToString: @"Cache"]
          || [infos.filename isEqualToString: @"Caches"]
          || [infos.filename isEqualToString: @"CoreServices"]
          || [infos.filename isEqualToString: @"Daemons"]
          || [infos.filename isEqualToString: @"DCIM"]
          || [infos.filename isEqualToString: @"Developer"]
          || [infos.filename isEqualToString: @"Documents"]
          || [infos.filename isEqualToString: @"Extensions"]
          || [infos.filename isEqualToString: @"Fonts"]
          || [infos.filename isEqualToString: @"Frameworks"]
          || [infos.filename isEqualToString: @"Filesystems"]
          || [infos.filename isEqualToString: @"Internet Plug-Ins"]
          || [infos.filename isEqualToString: @"Keyboard"]
          || [infos.filename isEqualToString: @"LaunchAgents"]
          || [infos.filename isEqualToString: @"LaunchDaemons"]
          || [infos.filename isEqualToString: @"Library"]
          || [infos.filename isEqualToString: @"Mail"]
          || [infos.filename isEqualToString: @"Managed Preferences"]
          || [infos.filename isEqualToString: @"MobileDevice"]
          || [infos.filename isEqualToString: @"Media"]
          || [infos.filename isEqualToString: @"Photos"]
          || [infos.filename isEqualToString: @"PlugIns"]
          || [infos.filename isEqualToString: @"Plugins"]
          || [infos.filename isEqualToString: @"Plug-Ins"]
          || [infos.filename isEqualToString: @"Printers"]
          || [infos.filename isEqualToString: @"PrivateFrameworks"]
          || [infos.filename isEqualToString: @"preferences"]
          || [infos.filename isEqualToString: @"Preferences"]
          || [infos.filename isEqualToString: @"ProvisioningProfiles"]
          || [infos.filename isEqualToString: @"Ringtones"]
          || [infos.filename isEqualToString: @"ServiceAgents"]
          || [infos.filename isEqualToString: @"System"]
          || [infos.filename isEqualToString: @"SystemConfiguration"]
          || [infos.filename isEqualToString: @"Thumbs"]
          || [infos.filename isEqualToString: @"Updates"]
          || [infos.filename isEqualToString: @"Tools"]
          || [infos.filename isEqualToString: @"tmp"]
          || [infos.filename isEqualToString: @"Wallpaper"])
        )
    {
        emblem = [UIImage imageNamed: [NSString stringWithFormat: @"Directory-%@.png", [infos.filename capitalizedString]]];
        
        if([[UIScreen mainScreen] scale] == 2)
        {
            CGContextDrawImage(context, CGRectMake(8, -64, 48, 48), emblem.CGImage);
        }
        else
        {
            CGContextDrawImage(context, CGRectMake(4, -32, 24, 24), emblem.CGImage);
        }
    }
    else if(infos.isImage)
    {
        emblem = [UIImage imageNamed: @"File-Image.png"];
        
        if([[UIScreen mainScreen] scale] == 2)
        {
            CGContextDrawImage(context, CGRectMake(8, -64, 48, 48), emblem.CGImage);
        }
        else
        {
            CGContextDrawImage(context, CGRectMake(4, -32, 24, 24), emblem.CGImage);
        }
    }
    else if(infos.isAudio == YES)
    {
        emblem = [UIImage imageNamed: @"File-Audio.png"];
        
        if([[UIScreen mainScreen] scale] == 2)
        {
            CGContextDrawImage(context, CGRectMake(8, -64, 48, 48), emblem.CGImage);
        }
        else
        {
            CGContextDrawImage(context, CGRectMake(4, -32, 24, 24), emblem.CGImage);
        }
    }
    else if
        (
         infos.isRegularFile &&
         ([[infos.fileExtension lowercaseString] isEqualToString: @"script"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"sh"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"bash"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"tcsh"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"zsc"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"csh"])
        )
    {
        emblem = [UIImage imageNamed: @"File-Script.png"];
        
        if([[UIScreen mainScreen] scale] == 2)
        {
            CGContextDrawImage(context, CGRectMake(8, -64, 48, 48), emblem.CGImage);
        }
        else
        {
            CGContextDrawImage(context, CGRectMake(4, -32, 24, 24), emblem.CGImage);
        }
    }
    else if
        (
         infos.isRegularFile &&
         ([[infos.fileExtension lowercaseString] isEqualToString: @"ttf"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"otf"])
        )
    {
        emblem = [UIImage imageNamed: @"File-Fonts.png"];
        
        if([[UIScreen mainScreen] scale] == 2)
        {
            CGContextDrawImage(context, CGRectMake(8, -64, 48, 48), emblem.CGImage);
        }
        else
        {
            CGContextDrawImage(context, CGRectMake(4, -32, 24, 24), emblem.CGImage);
        }
    }
    else if(infos.isRegularFile && [[infos.fileExtension lowercaseString] isEqualToString: @"plist"])
    {
        emblem = [UIImage imageNamed: @"File-Preferences.png"];
        
        if([[UIScreen mainScreen] scale] == 2)
        {
            CGContextDrawImage(context, CGRectMake(8, -64, 48, 48), emblem.CGImage);
        }
        else
        {
            CGContextDrawImage(context, CGRectMake(4, -32, 24, 24), emblem.CGImage);
        }
    }
    else if
        (
         infos.isDirectory &&
         ([[infos.fileExtension lowercaseString] isEqualToString: @"kext"]
          || [[infos.fileExtension lowercaseString] isEqualToString: @"plugin"])
        )
    {
        emblem = [UIImage imageNamed: @"Directory-Plugins.png"];
        
        if([[UIScreen mainScreen] scale] == 2)
        {
            CGContextDrawImage(context, CGRectMake(8, -64, 48, 48), emblem.CGImage);
        }
        else
        {
            CGContextDrawImage(context, CGRectMake(4, -32, 24, 24), emblem.CGImage);
        }
    }
    else if(infos.isDirectory && [[infos.fileExtension lowercaseString] isEqualToString: @"app"])
    {
        emblem = [UIImage imageNamed: @"Directory-Applications.png"];
        
        if([[UIScreen mainScreen] scale] == 2)
        {
            CGContextDrawImage(context, CGRectMake(8, -64, 48, 48), emblem.CGImage);
        }
        else
        {
            CGContextDrawImage(context, CGRectMake(4, -32, 24, 24), emblem.CGImage);
        }
    }
    else if(infos.isDirectory && [[infos.fileExtension lowercaseString] isEqualToString: @"framework"])
    {
        emblem = [UIImage imageNamed: @"Directory-Frameworks.png"];
        
        if([[UIScreen mainScreen] scale] == 2)
        {
            CGContextDrawImage(context, CGRectMake(8, -64, 48, 48), emblem.CGImage);
        }
        else
        {
            CGContextDrawImage(context, CGRectMake(4, -32, 24, 24), emblem.CGImage);
        }
    }
    else if(infos.isDirectory && [[infos.fileExtension lowercaseString] isEqualToString: @"bundle"])
    {
        emblem = [UIImage imageNamed: @"Directory-Bundles.png"];
        
        if([[UIScreen mainScreen] scale] == 2)
        {
            CGContextDrawImage(context, CGRectMake(8, -64, 48, 48), emblem.CGImage);
        }
        else
        {
            CGContextDrawImage(context, CGRectMake(4, -32, 24, 24), emblem.CGImage);
        }
    }
    
    if(_isSymbolicLink == YES)
    {
        emblem = [UIImage imageNamed: @"Emblem-SymLink.png"];
        
        CGContextDrawImage(context, frame, emblem.CGImage);
        
        if([[UIScreen mainScreen] scale] == 2)
        {
            frame.origin.x = -32;
        }
        else
        {
            frame.origin.x = -16;
        }
    }
    
    if(infos.isReadable == NO)
    {
        emblem = [UIImage imageNamed: @"Emblem-Unreadable.png"];
        
        CGContextDrawImage(context, frame, emblem.CGImage);
    }
    
    finalIcon = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return finalIcon;
}

//- (void)getIcon {
//    OSFile  * infos;
//    UIImage * baseIcon;
//    
//    infos = (_isSymbolicLink) ? _targetFile : self;
//    
//    if(infos.isDirectory == YES) {
//        baseIcon = [UIImage imageNamed: @"Directory.png"];
//    }
//    else if(infos.isExecutable == YES) {
//        baseIcon = [UIImage imageNamed: @"Executable.png"];
//    }
//    else if(infos.isSocket == YES) {
//        baseIcon = [UIImage imageNamed: @"Socket.png"];
//    }
//    else if(infos.isCharacterSpecial == YES) {
//        baseIcon = [UIImage imageNamed: @"Device-Character.png"];
//    }
//    else if(infos.isBlockSpecial == YES) {
//        baseIcon = [UIImage imageNamed: @"Device-Block.png"];
//    }
//    else {
//        baseIcon = [UIImage imageNamed: @"File.png"];
//    }
//    
//    _icon = [self iconByAddingEmblemsToImage: baseIcon];
//}


- (NSString *)description {
    NSMutableString *attstring = @"".mutableCopy;
    if (self.filename) {
        [attstring appendString:[NSString stringWithFormat:@"%@: %@\n", NSStringFromSelector(@selector(filename)), self.filename]];
    }
    if (self.type) {
        [attstring appendString:[NSString stringWithFormat:@"%@: %@\n",  NSStringFromSelector(@selector(type)), self.type]];
    }
    [attstring appendString:[NSString stringWithFormat:@"%@: %@\n",  NSStringFromSelector(@selector(size)), [NSString transformedFileSizeValue:@(self.size)]]];
    if (self.isDirectory) {
        [attstring appendString:[NSString stringWithFormat:@"%@: %@\n",  NSStringFromSelector(@selector(numberOfSubFiles)), @(self.numberOfSubFiles)]];
    }
    if (self.creationDate) {
        [attstring appendString:[NSString stringWithFormat:@"%@: %@\n",  NSStringFromSelector(@selector(creationDate)), self.creationDate.mediumString]];
    }
    if (self.modificationDate) {
        [attstring appendString:[NSString stringWithFormat:@"%@: %@\n",  NSStringFromSelector(@selector(modificationDate)), self.modificationDate.mediumString]];
    }
    if (self.path) {
        [attstring appendString:[NSString stringWithFormat:@"\n\n%@: %@\n", NSStringFromSelector(@selector(path)), self.path]];
    }
    return attstring;
}

@end

