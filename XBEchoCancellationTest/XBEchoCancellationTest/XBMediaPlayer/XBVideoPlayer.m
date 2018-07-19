//
//  XBVideoPlayer.m
//  XBAVPlayer
//
//  Created by xxb on 2017/6/23.
//  Copyright © 2017年 xxb. All rights reserved.
//

#import "XBVideoPlayer.h"
#import "MBProgressHUD.h"

@interface XBVideoPlayer ()

@property (nonatomic,strong) UIView *waitView;

//处于展示等待界面的状态
@property (nonatomic,assign) BOOL isWaitting;

@property (nonatomic,strong) AVPlayerLayer *playerLayer; //播放器显示层

@end

@implementation XBVideoPlayer

#pragma mark - 生命周期
-(instancetype)initWithFrame:(CGRect)frame
{
    if (self == [super initWithFrame:frame])
    {
        [self addNotice];
    }
    return self;
}
-(void)dealloc
{
    [self removeNotice];
    
    NSLog(@"XBVideoPlayer销毁");
}


#pragma mark - 其他方法
-(void)updatePlayerLayerFrame
{
    [self.superview layoutIfNeeded];
    NSLog(@"updatePlayerLayerFrame%@",NSStringFromCGRect(self.bounds));
    
    self.playerLayer.frame = self.bounds;
}

#pragma mark - 方法重写


-(void)setBl_layout_vertical:(LayoutBlock_vertical)bl_layout_vertical
{
    _bl_layout_vertical = bl_layout_vertical;
    
    if (bl_layout_vertical)
    {
        WEAK_SELF
        
        bl_layout_vertical(weakSelf);
    }
}


- (void)playItemDidChanged
{
    if (self.playerLayer)
    {
        [self.playerLayer removeFromSuperlayer];
        self.playerLayer = nil;
    }
    NSLog(@"XBVideoPlayer->changePlayItem->当前线程%@",[NSThread currentThread]);
}


- (AVPlayer *)player
{
    AVPlayer *player = [super player];
    if (self.playerLayer == nil)
    {
        NSLog(@"XBVideoPlayer->player->当前线程%@",[NSThread currentThread]);
        //创建播放器层
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
        //self.playerLayer.backgroundColor = [UIColor orangeColor].CGColor;
        [self updatePlayerLayerFrame];
        //self.playerLayer.videoGravity=AVLayerVideoGravityResizeAspect;//视频填充模式
        [self.layer addSublayer:self.playerLayer];
        
        WEAK_SELF
        if (self.bl_buildUI)
        {
            self.bl_buildUI(weakSelf);
        }
        [self videoPlayerBuildUI];
    }

    return player;
}

- (void)videoPlayerBuildUI
{

}

-(void)deviceOrientationDidChanged:(NSInteger)orientation
{
    WEAK_SELF
    if (orientation == 3 || orientation == 4)
    {
        if (self.bl_layout_horizontal)
        {
            self.bl_layout_horizontal(weakSelf);
        }
    }
    else if(orientation == 1)
    {
        if (self.bl_layout_vertical)
        {
            self.bl_layout_vertical(weakSelf);
        }
    }
    else if (orientation == 2)
    {
        
    }
    else
    {
        
    }
    [self updatePlayerLayerFrame];
}

//播放卡住了（网络不好）
- (void)SmoothStopCurrentProgress:(NSTimeInterval)CurrentProgress totalProgress:(NSTimeInterval)totalProgress
{
    [self showWaitView];
}

//播放重新开始
- (void)smoothNormalCurrentProgress:(NSTimeInterval)CurrentProgress totalProgress:(NSTimeInterval)totalProgress
{
    [self hiddenWaitView];
}

///当前缓冲到哪里了
- (void)totalBuffer:(CGFloat)totalBuffer
{

}

///播放进度
- (void)playProgress:(CGFloat)progress current:(CGFloat)current total:(CGFloat)total
{

}

///某个视频播放结束后调用
- (void)playbackFinish
{

}

//调用了play方法，并且可以播放（显示等待）
- (void)playFunSuccess
{
    [self showWaitView];
}
 
//调用了play方法，并且不可播放（展示错误）
- (void)playFunFailure
{
    
}
//视频缓冲了一部分，可以播放了（隐藏等待）
- (void)readyToPlay
{
    [self hiddenWaitView];
}
//要播放第某个视频出错
- (void)playIndexFaiulre:(NSInteger)index
{
    
}

-(void)continuePlay
{
    [super continuePlay];
}

-(void)pause
{
    [super pause];
}


#pragma mark - 通知
- (void)addNotice
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
}
- (void)removeNotice
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}


- (void)appWillResignActive:(NSNotification *)notification
{
    if (self.player) {
        [self.player pause];
        self.lastTime = CMTimeGetSeconds(self.player.currentTime);
    }
}

- (void)appBecomeActive:(NSNotification *)notification
{
    [self seekToTime:self.lastTime];
}



#pragma mark - UI事件

- (void)showWaitView
{
    if (self.isWaitting == NO)
    {
        if (self.waitView)
        {
            self.waitView.hidden = NO;
        }
        else
        {
            [MBProgressHUD showHUDAddedTo:self animated:YES];
        }
        self.isWaitting = YES;
    }
}

- (void)hiddenWaitView
{
    if (self.isWaitting == YES)
    {
        if (self.waitView)
        {
            self.waitView.hidden = YES;
        }
        else
        {
            [MBProgressHUD hideHUDForView:self animated:YES];
        }
        self.isWaitting = NO;
    }
}





#pragma mark - 懒加载
-(UIView *)waitView
{
    if (_waitView == nil)
    {
        if (self.bl_waitView)
        {
            WEAK_SELF
            _waitView = self.bl_waitView(weakSelf);
            _waitView.hidden = YES;
        }
    }
    return _waitView;
}



#pragma mark - 其他方法
//将时间转换成00:00:00格式
- (NSString *)formatPlayTime:(NSTimeInterval)duration
{
    int minute = 0, hour = 0, secend = duration;
    minute = (secend % 3600)/60;
    hour = secend / 3600;
    secend = secend % 60;
    return [NSString stringWithFormat:@"%02d:%02d:%02d", hour, minute, secend];
}

/*
//处理滑块
- (void)progressValueChange:(AC_ProgressSlider *)slider
{
    //当视频状态为AVPlayerStatusReadyToPlay时才处理（当视频没加载的时候，直接禁止掉滑块事件）
    if (self.avPlayer.status == AVPlayerStatusReadyToPlay) {
        NSTimeInterval duration = self.slider.sliderPercent* CMTimeGetSeconds(self.avPlayer.currentItem.duration);
        CMTime seekTime = CMTimeMake(duration, 1);
        
        [self.avPlayer seekToTime:seekTime completionHandler:^(BOOL finished) {
            
        }];
    }
}
 */
@end
