//
//  XBAudioPlayer.m
//  XBMediaPlayer
//
//  Created by xxb on 2017/6/24.
//  Copyright © 2017年 xxb. All rights reserved.
//

#import "XBAudioPlayer.h"

@implementation XBAudioPlayer

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
    
    NSLog(@"XBAudioPlayer销毁");
}

#pragma mark - 方法重写
///屏幕方向改变了
- (void)deviceOrientationDidChanged:(NSInteger)orientation
{

}

///播放卡住了（网络不好）
- (void)SmoothStopCurrentProgress:(NSTimeInterval)CurrentProgress totalProgress:(NSTimeInterval)totalProgress
{

}

///播放重新开始
- (void)smoothNormalCurrentProgress:(NSTimeInterval)CurrentProgress totalProgress:(NSTimeInterval)totalProgress
{

}

///当前缓冲到哪里了
- (void)totalBuffer:(CGFloat)totalBuffer
{

}

///播放进度
- (void)playProgress:(CGFloat)progress current:(CGFloat)current total:(CGFloat)total
{

}

///某个item播放结束后调用
- (void)playbackFinish
{

}

///调用了play方法，并且可以播放（显示等待）
- (void)playFunSuccess
{
    //设置后台播放
    if ([[XBAudioModeManager shared] currentMode] == XBAudioMode_playback)
    {
        return;
    }
    [[XBAudioModeManager shared] playbackMode];
}

///调用了play方法，并且不可播放（展示错误）
- (void)playFunFailure
{

}

///item缓冲了一部分，可以播放了（隐藏等待）
- (void)readyToPlay
{

}

///要播放第某个item出错
- (void)playIndexFaiulre:(NSInteger)index
{

}



#pragma mark - 通知
- (void)addNotice
{
    //添加通知，拔出耳机后暂停播放
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChange:) name:AVAudioSessionRouteChangeNotification object:nil];
}
- (void)removeNotice
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
}
/**
 *  一旦输出改变则执行此方法
 *
 *  @param notification 输出改变通知对象
 */
-(void)routeChange:(NSNotification *)notification{
    NSDictionary *dic=notification.userInfo;
    int changeReason= [dic[AVAudioSessionRouteChangeReasonKey] intValue];
    //等于AVAudioSessionRouteChangeReasonOldDeviceUnavailable表示旧输出不可用
    if (changeReason==AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        AVAudioSessionRouteDescription *routeDescription=dic[AVAudioSessionRouteChangePreviousRouteKey];
        AVAudioSessionPortDescription *portDescription= [routeDescription.outputs firstObject];
        //原设备为耳机则暂停
        if ([portDescription.portType isEqualToString:@"Headphones"]) {
            [self pause];
        }
    }
    
    //    [dic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    //        NSLog(@"%@:%@",key,obj);
    //    }];
}

@end
