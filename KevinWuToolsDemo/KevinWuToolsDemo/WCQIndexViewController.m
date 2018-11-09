//
//  WCQIndexViewController.m
//  KevinWuToolsDemo
//
//  Created by KevinWu on 2018/6/9.
//  Copyright © 2018年 wcq. All rights reserved.
//

#import "WCQIndexViewController.h"
#import "NextPageViewController.h"
@interface WCQIndexViewController ()

@end

@implementation WCQIndexViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"首页";
    self.view.backgroundColor = UIColor.grayColor;
    [self.view addSubview:({
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(100, 200, 300, 200);
        [btn setTitle:@"下一页" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(didPressNextPage:) forControlEvents:UIControlEventTouchUpInside];
        btn;
    })];
    // Do any additional setup after loading the view.
}

- (void)didPressNextPage:(UIButton *)sender {
    [self.navigationController pushViewController:NextPageViewController.new animated:YES];
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
