//
//  GitMainViewController.m
//  GitTest
//
//  Created by 云尚互动 on 15/12/1.
//  Copyright © 2015年 云尚互动. All rights reserved.
//

#import "GitMainViewController.h"
#import "GitSubViewController.h"

@interface GitMainViewController ()

@end

@implementation GitMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(100, 200, 100, 100);
    [button setTitle: @"点我直播" forState:UIControlStateNormal];
    button.backgroundColor = [UIColor redColor];
    [button addTarget:self action:@selector(nextVC) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)nextVC
{
    GitSubViewController *sub = [[GitSubViewController alloc]init];
    
    [self.navigationController pushViewController:sub animated:YES];
    
}


@end
