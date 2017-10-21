//
//  OSSettingViewController.m
//  FileDownloader
//
//  Created by Swae on 2017/10/21.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSSettingViewController.h"
#import "OSSettingsTableViewCell.h"
#import "OSSettingsTableViewSection.h"

@interface OSSettingViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *settingTableView;
@property (nonatomic, strong) NSMutableArray<OSSettingsTableViewSection *> *sectionItems;

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
    [self.settingTableView reloadData];
}

- (OSSettingsTableViewSection *)section_1 {
    NSArray *items = @[
                       [OSSettingsMenuItem itemForType:OSSettingsMenuItemTypePassword]
                       ];
    OSSettingsTableViewSection *section = [[OSSettingsTableViewSection alloc] initWithItem:items headerTitle:nil footerText:nil];
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
    cell.disclosureSwitchChanged = ^(UISwitch *sw) {

    };
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

@end
