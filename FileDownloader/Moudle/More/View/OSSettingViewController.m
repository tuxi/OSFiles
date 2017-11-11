//
//  OSSettingViewController.m
//  OSFileDownloader
//
//  Created by Swae on 2017/10/21.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSSettingViewController.h"
#import "OSSettingsTableViewCell.h"
#import "OSSettingsTableViewSection.h"
#import "SmileAuthenticator.h"
#import "OSAuthenticatorHelper.h"
#import "OSFileDownloaderConfiguration.h"
#import "UIViewController+OSAlertExtension.h"
#import "OSFileDownloaderManager.h"
#import "OSAboutAppViewController.h"

@interface OSSettingViewController () <UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) UITableView *settingTableView;
@property (nonatomic, strong) NSMutableArray<OSSettingsTableViewSection *> *sectionItems;
@property (nonatomic, strong) UIImagePickerController *pickerViewController;

@end

@implementation OSSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.settingTableView];
    NSDictionary *subviewsDict = @{@"tableView": self.settingTableView};
    NSArray *constraints = @[
                             [NSLayoutConstraint constraintsWithVisualFormat:@"|[tableView]|" options:kNilOptions metrics:nil views:subviewsDict],
                             [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|" options:kNilOptions metrics:nil views:subviewsDict]
                             ];
    [self.view addConstraints:[constraints valueForKeyPath:@"@unionOfArrays.self"]];
    
    self.navigationItem.title = @"设置";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadSectionItems];
    
}

- (UITableView *)settingTableView {
    if (!_settingTableView) {
        _settingTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _settingTableView.translatesAutoresizingMaskIntoConstraints = NO;
        _settingTableView.delegate = self;
        _settingTableView.dataSource = self;
        [_settingTableView registerNib:[UINib nibWithNibName:@"OSSettingsTableViewCell" bundle:nil] forCellReuseIdentifier:@"OSSettingsTableViewCell"];
    }
    return _settingTableView;
}

- (void)loadSectionItems {
    self.sectionItems = [NSMutableArray arrayWithCapacity:0];
    [self.sectionItems addObject:[self section_1]];
    [self.sectionItems addObject:[self section_2]];
    [self.sectionItems addObject:[self section_3]];
    [self.settingTableView reloadData];
}

- (OSSettingsTableViewSection *)section_1 {
    BOOL hasPassword = [SmileAuthenticator hasPassword];
    NSMutableArray *items = @[
                       [OSSettingsMenuItem switchCellForSel:@selector(disclosureSwitchChanged:) target:self title:@"设置启动密码" iconName:@"settings-zero" on:hasPassword]
                       ].mutableCopy;
    if (hasPassword) {
        [items addObject:[OSSettingsMenuItem cellForSel:@selector(changePassword:) target:self title:@"修改密码" disclosureText:nil iconName:nil disclosureType:OSSettingsMenuItemDisclosureTypeViewController]];
        BOOL hasBackgroundImage = [[OSAuthenticatorHelper sharedInstance] hasBackgroundImage];
        if (hasBackgroundImage) {
         [items addObject:[OSSettingsMenuItem normalCellForSel:@selector(setUnlockBackgroundImage:) target:self title:@"设置解锁背景图片" iconName:nil]];
             // 如果设置了背景图片，就添加可以点击的清除背景图的cell
            [items addObject:[OSSettingsMenuItem normalCellForSel:@selector(clearBackgroundImage:) target:self title:@"清除解锁背景图片" iconName:nil]];
        }
        else {
            [items addObject:[OSSettingsMenuItem switchCellForSel:@selector(setUnlockBackgroundImage:) target:self title:@"设置解锁背景图片" iconName:nil on:hasBackgroundImage]];
        }
        
    }
    OSSettingsTableViewSection *section = [[OSSettingsTableViewSection alloc] initWithItem:items headerTitle:@"通用" footerText:nil];
    return section;
}

- (OSSettingsTableViewSection *)section_2 {
    NSNumber *maxConcurrentDownloads = [OSFileDownloaderConfiguration defaultConfiguration].maxConcurrentDownloads;
    NSNumber *shouldAutoDownloadWhenFailure = [OSFileDownloaderConfiguration defaultConfiguration].shouldAutoDownloadWhenFailure;
    NSNumber *shouldAutoDownloadWhenInitialize = [OSFileDownloaderConfiguration defaultConfiguration].shouldAutoDownloadWhenInitialize;
    NSNumber *shouldAllowDownloadOnCellularNetwork = [[OSFileDownloaderConfiguration defaultConfiguration] shouldAllowDownloadOnCellularNetwork];
    NSNumber *shouldSendNotificationWhenDownloadComplete = [[OSFileDownloaderConfiguration defaultConfiguration] shouldSendNotificationWhenDownloadComplete];
    NSMutableArray *items = @[
                              [OSSettingsMenuItem cellForSel:@selector(setMaxConcurrentDownloads) target:self title:@"最大同时下载数量" disclosureText:[maxConcurrentDownloads stringValue] iconName:nil disclosureType:OSSettingsMenuItemDisclosureTypeViewControllerWithDisclosureText],
                              [OSSettingsMenuItem switchCellForSel:@selector(autoDownloadFailure:) target:self title:@"WIFI下失败自动重试" iconName:nil on:[shouldAutoDownloadWhenFailure boolValue]],
                              [OSSettingsMenuItem switchCellForSel:@selector(autoDownloadWhenInitialize:) target:self title:@"程序启动时自动下载" iconName:nil on:[shouldAutoDownloadWhenInitialize boolValue]],
                              [OSSettingsMenuItem switchCellForSel:@selector(allowDownloadOnCellularNetwork:) target:self title:@"允许蜂窝网络下载" iconName:nil on:[shouldAllowDownloadOnCellularNetwork boolValue]],
                              [OSSettingsMenuItem switchCellForSel:@selector(sendNotificationWhenDownloadComplete:) target:self title:@"下载完成后通知您" iconName:nil on:[shouldSendNotificationWhenDownloadComplete boolValue]],
                              ].mutableCopy;
    OSSettingsTableViewSection *section = [[OSSettingsTableViewSection alloc] initWithItem:items headerTitle:@"下载" footerText:nil];
    return section;
}

- (OSSettingsTableViewSection *)section_3 {
    NSArray *items = @[
                       [OSSettingsMenuItem normalCellForSel:@selector(aboutApp) target:self title:@"关于" iconName:nil]
                              ];
    OSSettingsTableViewSection *section = [[OSSettingsTableViewSection alloc] initWithItem:items headerTitle:@"" footerText:nil];
    return section;
}


////////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewDataSource
////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sectionItems.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    OSSettingsTableViewSection *sectionItem = self.sectionItems[section];
    return sectionItem.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    OSSettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OSSettingsTableViewCell" forIndexPath:indexPath];
    OSSettingsTableViewSection *section = self.sectionItems[indexPath.section];
    cell.menuItem = section.items[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *header = [self.sectionItems[section] headerTitle];
    if (header.length) {
        return header;
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *footer = [self.sectionItems[section] footerText];
    if (footer.length) {
        return footer;
    }
    return nil;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Switch
////////////////////////////////////////////////////////////////////////


/// 修改密码
- (void)changePassword:(id)obj {
    [SmileAuthenticator sharedInstance].securityType = INPUT_THREE;
    [[SmileAuthenticator sharedInstance] presentAuthViewControllerAnimated:TRUE showNavigation:TRUE];
}

/// 打开密码
- (void)passwordSwitch:(UISwitch*)passwordSwitch {
    if (passwordSwitch.on) {
        [SmileAuthenticator sharedInstance].securityType = INPUT_TWICE;
    } else {
        [SmileAuthenticator sharedInstance].securityType = INPUT_ONCE;
    }
    
    [[SmileAuthenticator sharedInstance] presentAuthViewControllerAnimated:TRUE showNavigation:TRUE];
}

/// 清除背景图片
- (void)clearBackgroundImage:(id)obj {
    [[OSAuthenticatorHelper sharedInstance] clearBackgroundImage];
    [self loadSectionItems];
}

/// 设置解锁页背景图片
- (void)setUnlockBackgroundImage:(id)obj {
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"请选择图片来源" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    //从照相机拍照
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"照相机" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            self.pickerViewController = [[UIImagePickerController alloc] init];
            self.pickerViewController.delegate = self;//设置UIImagePickerController的代理，同时要遵循UIImagePickerControllerDelegate，UINavigationControllerDelegate协议
//            self.pickerViewController.allowsEditing = YES;//设置拍照之后图片是否可编辑，如果设置成可编辑的话会在代理方法返回的字典里面多一些键值。PS：如果在调用相机的时候允许照片可编辑，那么用户能编辑的照片的位置并不包括边角。
            self.pickerViewController.sourceType = UIImagePickerControllerSourceTypeCamera;//UIImagePicker选择器的数据来源，UIImagePickerControllerSourceTypeCamera说明数据来源于摄像头
            [self presentViewController:self.pickerViewController animated:YES completion:nil];
        }else{
            
            NSLog(@"哎呀,没有摄像头");
        }
        
    }];
    
    //从手机相册选取
    UIAlertAction *photoAction = [UIAlertAction actionWithTitle:@"相册" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
            self.pickerViewController = [[UIImagePickerController alloc]init];
            self.pickerViewController.delegate = self;
//            self.pickerViewController.allowsEditing = YES;//是否可以对原图进行编辑
            
            //设置图片选择器的数据来源为手机相册
            self.pickerViewController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [self presentViewController:self.pickerViewController animated:YES completion:nil];
        }
        else{
            
            NSLog(@"图片库不可用");
            
        }
    }];
    
    //取消
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [alertC addAction:cameraAction];
    [alertC addAction:photoAction];
    [alertC addAction:cancelAction];
    [self presentViewController:alertC animated:YES completion:nil];
    [self loadSectionItems];
}

- (void)disclosureSwitchChanged:(UISwitch *)sw {
    [self passwordSwitch:sw];
}

- (void)setMaxConcurrentDownloads {
    [self alertControllerWithTitle:@"设置最大同时下载数量"
                           message:@"请输入一个大于0的数字"
                           content:nil
                       placeholder:nil
                      keyboardType:UIKeyboardTypeNamePhonePad
                               blk:^(UITextField *textField) {
                                   NSString *num = textField.text;
                                   NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
                                   NSNumber *strNum = [nf numberFromString:num];
                                   if (!strNum) {
                                       strNum = [[OSFileDownloaderConfiguration defaultConfiguration] maxConcurrentDownloads];
                                   }
                                   [[OSFileDownloaderConfiguration defaultConfiguration] setMaxConcurrentDownloads:strNum];
                                   [[OSFileDownloaderManager sharedInstance] setMaxConcurrentDownloads:[strNum integerValue]];
                                   [self loadSectionItems];
                               }];
}

- (void)autoDownloadFailure:(UISwitch *)sw {
    [[OSFileDownloaderConfiguration defaultConfiguration] setShouldAutoDownloadWhenFailure:@(sw.isOn)];
    if (sw.isOn) {
        [self xy_showMessage:@"下载失败后，\n每隔10秒钟重试下载，\n只在WIFI下进行"];
    }
}

- (void)autoDownloadWhenInitialize:(UISwitch *)sw {
    [[OSFileDownloaderConfiguration defaultConfiguration] setShouldAutoDownloadWhenInitialize:@(sw.isOn)];
    if (sw.isOn) {
        [self xy_showMessage:@"App在启动时会自动为您下载上次未完成任务"];
    }
}

- (void)allowDownloadOnCellularNetwork:(UISwitch *)sw {
    [[OSFileDownloaderConfiguration defaultConfiguration] setShouldAllowDownloadOnCellularNetwork:@(sw.isOn)];
    if (sw.isOn) {
        [self xy_showMessage:@"已为您开启蜂窝网络下载，建议您关闭此开关"];
    }
    else {
        [self xy_showMessage:@"已为您关闭蜂窝网络下载"];
    }
}

- (void)sendNotificationWhenDownloadComplete:(UISwitch *)sw {
    [[OSFileDownloaderConfiguration defaultConfiguration] setShouldSendNotificationWhenDownloadComplete:@(sw.isOn)];
}

- (void)aboutApp {
    OSAboutAppViewController *vc = [OSAboutAppViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UIImagePickerControllerDelegate
/// 拍照/选择图片结束
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    //获取图片
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];//原始图片
//    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];//编辑后的图片
    
    [[OSAuthenticatorHelper sharedInstance] saveImage:image];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

/// 取消拍照/选择图片
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self loadSectionItems];
}


@end
