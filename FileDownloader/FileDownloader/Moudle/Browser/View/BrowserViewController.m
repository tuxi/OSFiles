//
//  BrowserViewController.m
//  FileDownloader
//
//  Created by Ossey on 2017/6/10.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "BrowserViewController.h"
#import "UITextField+Blocks.h"
#import "OSDownloaderModule.h"
#import "OSFileItem.h"

@interface BrowserViewController ()
@property (weak, nonatomic) IBOutlet UITextField *textField;

@end

@implementation BrowserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.textField.shouldReturnBlock = ^BOOL(UITextField *textField) {
      
        [[OSDownloaderModule sharedInstance] start:textField.text];
        return YES;
    };
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
