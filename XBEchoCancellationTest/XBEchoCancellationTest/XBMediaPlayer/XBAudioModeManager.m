//
//  XBAudioModeManager.m
//  XBMediaPlayer
//
//  Created by xxb on 2017/6/24.
//  Copyright © 2017年 xxb. All rights reserved.
//

#import "XBAudioModeManager.h"
#import <AVFoundation/AVFoundation.h>

@interface XBAudioModeManager ()
@property (nonatomic,strong) AVAudioSession *audioSession;
@end

@implementation XBAudioModeManager


#pragma mark - 生命周期
+ (instancetype)shared
{
    return [XBAudioModeManager new];
}
+(instancetype)allocWithZone:(struct _NSZone *)zone
{
    static XBAudioModeManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [super allocWithZone:zone];
    });
    return manager;
}

#pragma mark - 实例方法
//                               	是否要求输入	是否要求输出	是否遵从静音键

///混音播放，可以与其他音频应用同时播放,      否           是           是
- (void)ambientMode
{
    [self.audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
    [self setActive:YES];
}
///独占播放                              否           是           是
- (void)soloAmbientMode
{
    [self.audioSession setCategory:AVAudioSessionCategorySoloAmbient error:nil];
    [self setActive:YES];
}
///后台播放，也是独占的                   	否           是           否
- (void)playbackMode
{
    [self.audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [self setActive:YES];
}
///录音模式，用于录音时使用                  是           否           否
- (void)recordMode
{
    [self.audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    [self setActive:YES];
}
///播放和录音，此时可以录音也可以播放          是           是           否
- (void)playAndRecordMode
{
    [self.audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [self setActive:YES];
}
///硬件解码音频，此时不能播放和录制            否           否           否
- (void)audioProcessingMode
{
    [self.audioSession setCategory:AVAudioSessionCategoryAudioProcessing error:nil];
    [self setActive:YES];
}
///多种输入输出，例如可以耳机、USB设备同时播放   是           是           否
- (void)multiRouteMode
{
    [self.audioSession setCategory:AVAudioSessionCategoryMultiRoute error:nil];
    [self setActive:YES];
}

/*
 如果一个应用已经在播放音频，打开我们的应用之后设置了在后台播放的会话类型，此时其他应用的音频会停止而播放我们的音频，如果希望我们的程序音频播放完之后（关闭或退出到后台之后）能够继续播放其他应用的音频的话则可以调用setActive::方法关闭会话
 */
///活跃或者不活跃
- (void)setActive:(BOOL)active
{
    [self.audioSession setActive:active error:nil];
}

- (XBAudioMode)currentMode
{
    if ([self.audioSession.category isEqualToString:AVAudioSessionCategoryAmbient])
    {
        return XBAudioMode_ambient;
    }
    else if ([self.audioSession.category isEqualToString:AVAudioSessionCategorySoloAmbient])
    {
        return XBAudioMode_soloAmbient;
    }
    else if ([self.audioSession.category isEqualToString:AVAudioSessionCategoryPlayback])
    {
        return XBAudioMode_playback;
    }
    else if ([self.audioSession.category isEqualToString:AVAudioSessionCategoryRecord])
    {
        return XBAudioMode_record;
    }
    else if ([self.audioSession.category isEqualToString:AVAudioSessionCategoryPlayAndRecord])
    {
        return XBAudioMode_playAndRecord;
    }
    else if ([self.audioSession.category isEqualToString:AVAudioSessionCategoryAudioProcessing])
    {
        return XBAudioMode_audioProcessing;
    }
//    else if ([self.audioSession.category isEqualToString:AVAudioSessionCategoryMultiRoute])
    else
    {
        return XBAudioMode_multiRoute;
    }
    
}


///app开启远程控制
- (void)appReceivingRemoteControl
{
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}
///app取消远程控制
- (void)appEndReceivingRemoteControl
{
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}


#pragma mark - 懒加载
- (AVAudioSession *)audioSession
{
    if (_audioSession == nil)
    {
        _audioSession = [AVAudioSession sharedInstance];
    }
    return _audioSession;
}
@end
