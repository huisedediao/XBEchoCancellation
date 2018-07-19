//
//  XBAudioModeManager.h
//  XBMediaPlayer
//
//  Created by xxb on 2017/6/24.
//  Copyright © 2017年 xxb. All rights reserved.


//  如果一个应用已经在播放音频，打开我们的应用之后设置了在后台播放的会话类型，此时其他应用的音频会停止而播放我们的音频，如果希望我们的程序音频播放完之后（关闭或退出到后台之后）能够继续播放其他应用的音频的话则可以调用setActive::方法关闭会话
//  为了能够让应用退到后台之后支持耳机控制，建议添加远程控制事件

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    XBAudioMode_ambient,
    XBAudioMode_soloAmbient,
    XBAudioMode_playback,
    XBAudioMode_record,
    XBAudioMode_playAndRecord,
    XBAudioMode_audioProcessing,
    XBAudioMode_multiRoute,
} XBAudioMode;

@interface XBAudioModeManager : NSObject

+ (instancetype)shared;

- (XBAudioMode)currentMode;

//                               	是否要求输入	是否要求输出	是否遵从静音键

///混音播放，可以与其他音频应用同时播放,      否           是           是
- (void)ambientMode;

///独占播放                              否           是           是
- (void)soloAmbientMode;

///后台播放，也是独占的                   	否           是           否
- (void)playbackMode;

///录音模式，用于录音时使用                  是           否           否
- (void)recordMode;

///播放和录音，此时可以录音也可以播放          是           是           否
- (void)playAndRecordMode;

///硬件解码音频，此时不能播放和录制            否           否           否
- (void)audioProcessingMode;

///多种输入输出，例如可以耳机、USB设备同时播放   是           是           否
- (void)multiRouteMode;


/*
 如果一个应用已经在播放音频，打开我们的应用之后设置了在后台播放的会话类型，此时其他应用的音频会停止而播放我们的音频，如果希望我们的程序音频播放完之后（关闭或退出到后台之后）能够继续播放其他应用的音频的话则可以调用setActive::方法关闭会话
 */
///活跃或者不活跃
- (void)setActive:(BOOL)active;


///app开启远程控制
- (void)appReceivingRemoteControl;

///app取消远程控制
- (void)appEndReceivingRemoteControl;

@end
