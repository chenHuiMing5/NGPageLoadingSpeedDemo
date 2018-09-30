//
//  FirstViewController.m
//  NGPageLoadingDemo
//
//  Created by ngmmxh on 2018/8/26.
//  Copyright © 2018年 ngmmxh. All rights reserved.
//

#import "FirstViewController.h"
#import "TwoViewController.h"
@interface FirstViewController ()

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UIButton *btnEnter = [UIButton buttonWithType:UIButtonTypeCustom];
    btnEnter.frame = CGRectMake(100, 100, 100, 100);
    btnEnter.backgroundColor = [UIColor redColor];
    [btnEnter addTarget:self action:@selector(onClickBtnEnter) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btnEnter];
}

-(void)onClickBtnEnter{
    TwoViewController *twoVC = [[TwoViewController alloc] init];
    [self.navigationController pushViewController:twoVC animated:YES];
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
