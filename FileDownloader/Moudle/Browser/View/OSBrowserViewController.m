//
//  OSBrowserViewController.m
//  OSFileDownloader
//
//  Created by Ossey on 2017/6/10.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSBrowserViewController.h"
#import "UITextField+Blocks.h"
#import "OSFileDownloaderManager.h"

@interface OSBrowserViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *textField;

@end

@implementation OSBrowserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.textField.delegate = self;
    self.textField.shouldReturnBlock = ^BOOL(UITextField *textField) {
      
        [[OSFileDownloaderManager sharedInstance] start:textField.text];
        return YES;
    };
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.textField resignFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    if ([textField.text hasPrefix:@"http"]) {
        [[OSFileDownloaderManager sharedInstance] start:textField.text];
    }
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
