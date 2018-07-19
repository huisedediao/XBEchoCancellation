//
//  XBEffectSoundPlayer.m
//  MediaStudy
//
//  Created by xxb on 2017/4/21.
//  Copyright © 2017年 xxb. All rights reserved.
//

#import "XBEffectSoundPlayer.h"
#import <AudioToolbox/AudioToolbox.h>

@interface XBEffectSoundPlayer ()
{
    SystemSoundID soundID;
}
@end

@implementation XBEffectSoundPlayer


#pragma mark - 生命周期


+ (instancetype)shared
{
    return [self new];
}

+(instancetype)allocWithZone:(struct _NSZone *)zone
{
    static XBEffectSoundPlayer *player = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        player = [super allocWithZone:zone];
    });
    return player;
}




#pragma mark - 方法
/**
 *  播放完成回调函数
 *
 *  @param soundID    系统声音ID
 *  @param clientData 回调时传递的数据
 */
void soundCompleteCallback(SystemSoundID soundID,void * clientData){
    NSLog(@"播放完成...");
}



/**
 *  停止播放
 */
- (void)stopSoundPlay
{
    AudioServicesDisposeSystemSoundID(soundID);
}



/**
 *  播放音效文件
 *
 *  @param soundName 音频文件名称
 */
- (void)playSoundEffect:(NSString *)soundName
{
    //停止上一个正在播放的音乐
    [self stopSoundPlay];
    
    NSString *audioFile=[[NSBundle mainBundle] pathForResource:soundName ofType:nil];
    NSURL *fileUrl=[NSURL fileURLWithPath:audioFile];
    //1.获得系统声音ID
    /**
     * inFileUrl:音频文件url
     * outSystemSoundID:声音id（此函数会将音效文件加入到系统音频服务中并返回一个长整形ID）
     */
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(fileUrl), &soundID);
    //如果需要在播放完之后执行某些操作，可以调用如下方法注册一个播放完成回调函数
    AudioServicesAddSystemSoundCompletion(soundID, NULL, NULL, soundCompleteCallback, NULL);
    //2.播放音频
    AudioServicesPlaySystemSound(soundID);//播放音效
    //    AudioServicesPlayAlertSound(soundID);//播放音效并震动
}

@end
