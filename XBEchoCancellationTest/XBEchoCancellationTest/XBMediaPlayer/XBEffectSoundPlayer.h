//
//  XBEffectSoundPlayer.h
//  MediaStudy
//
//  Created by xxb on 2017/4/21.
//  Copyright © 2017年 xxb. All rights reserved.
//  播放提示音，通知铃声

/*
音频播放时间不能超过30s
数据必须是PCM或者IMA4格式
音频文件必须打包成.caf、.aif、.wav中的一种（注意这是官方文档的说法，实际测试发现一些.mp3也可以播放）
 */

#import <Foundation/Foundation.h>

@interface XBEffectSoundPlayer : NSObject

+ (instancetype)shared;

/**
 播放声音
 参数：声音的名字，需带后缀，如：@"Bleep.wav"
 */
- (void)playSoundEffect:(NSString *)soundName;

/**
 停止当前正在播放的声音
 */
- (void)stopSoundPlay;

@end
