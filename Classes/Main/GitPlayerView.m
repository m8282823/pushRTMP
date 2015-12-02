//
//  GitPlayerView.m
//  GitTest
//
//  Created by 云尚互动 on 15/12/2.
//  Copyright © 2015年 云尚互动. All rights reserved.
//

#import "GitPlayerView.h"

@implementation GitPlayerView

+ (Class)layerClass{
    return [AVPlayerLayer class];
}

- (void)setPlayer:(AVPlayer *)player{
    [(AVPlayerLayer *)self.layer setPlayer:player];
}





/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
