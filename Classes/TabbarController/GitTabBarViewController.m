//
//  GitTabBarViewController.m
//  GitTest
//
//  Created by 云尚互动 on 15/12/1.
//  Copyright © 2015年 云尚互动. All rights reserved.
//

#import "GitTabBarViewController.h"
#import "GitMainNavigationController.h"
#import "GitMainViewController.h"
#import "GitMyNavigationController.h"
#import "GitMyViewController.h"

@interface GitTabBarViewController ()

@end

@implementation GitTabBarViewController



- (instancetype)init
{
    self = [super init];
    if (self) {
        GitMainViewController *mainViewController = [[GitMainViewController alloc]init];
        GitMainNavigationController *mainNav = [[GitMainNavigationController alloc]initWithRootViewController:mainViewController];
        
        
        GitMyViewController *myViewController = [[GitMyViewController alloc]init];
        GitMyNavigationController *myNav = [[GitMyNavigationController alloc]initWithRootViewController:myViewController];
        
        self.viewControllers = @[mainNav,myNav];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
