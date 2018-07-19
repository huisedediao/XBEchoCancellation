//
//  XBAudioRecorder.m
//  XBMediaPlayer
//
//  Created by xxb on 2017/6/24.
//  Copyright © 2017年 xxb. All rights reserved.
//

#import "XBAudioRecorder.h"
#import "XBAudioModeManager.h"

#define kRecordAudioFile @"myRecord.caf"

@interface XBAudioRecorder () <AVAudioRecorderDelegate>
@property (nonatomic,strong) AVAudioRecorder *audioRecorder;//音频录音机
@end

@implementation XBAudioRecorder


#pragma mark - 生命周期

+ (instancetype)shared
{
    return [XBAudioRecorder new];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static XBAudioRecorder *recorder = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        recorder = [super allocWithZone:zone];
    });
    return recorder;
}

-(instancetype)init
{
    if (self = [super init])
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [self setAudioSession];
        });
    }
    return self;
}


#pragma mark - 私有方法
/**
 *  设置音频会话
 */
-(void)setAudioSession
{
    [[XBAudioModeManager shared] recordMode];
}

/**
 *  取得录音文件保存路径
 *
 *  @return 录音文件路径
 */
-(NSString *)getSavePath
{
    NSString *urlStr=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    urlStr=[urlStr stringByAppendingPathComponent:kRecordAudioFile];

    NSLog(@"file path:%@",urlStr);
    return urlStr;
}


/**
 *  取得录音文件设置
 *
 *  @return 录音设置
 */
-(NSDictionary *)getAudioSetting{
    NSMutableDictionary *dicM=[NSMutableDictionary dictionary];
    //设置录音格式
    [dicM setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
    //设置录音采样率，8000是电话采样率，对于一般录音已经够了
    [dicM setObject:@(8000) forKey:AVSampleRateKey];
    //设置通道,这里采用单声道
    [dicM setObject:@(1) forKey:AVNumberOfChannelsKey];
    //每个采样点位数,分为8、16、24、32
    [dicM setObject:@(8) forKey:AVLinearPCMBitDepthKey];
    //是否使用浮点数采样
    [dicM setObject:@(YES) forKey:AVLinearPCMIsFloatKey];
    //....其他设置等
    return dicM;
}


#pragma mark - 控制
- (void)record
{
    if (![self.audioRecorder isRecording])
    {
        [self.audioRecorder deleteRecording];
        [self.audioRecorder record];//首次使用应用时如果调用record方法会询问用户是否允许使用麦克风
    }
}

- (void)pause
{
    if ([self.audioRecorder isRecording])
    {
        [self.audioRecorder pause];
    }
}

- (void)resume
{
    if (![self.audioRecorder isRecording])
    {
        [self record];
    }
}

- (void)stop
{
    [self.audioRecorder stop];
}

/// 声音大小 以百分比显示
- (CGFloat)volumePow
{
    [self.audioRecorder updateMeters];//更新测量值
    float power= [self.audioRecorder averagePowerForChannel:0];//取得第一个通道的音频，注意音频强度范围时-160到0
    CGFloat progress=(1.0/160.0)*(power+160.0);
    return progress;
}



#pragma mark - 录音机代理方法
/**
 *  录音完成，录音完成后播放录音
 *
 *  @param recorder 录音机对象
 *  @param flag     是否成功
 */
-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    if (flag)
    {
        NSLog(@"录音完成!");
    }
    else
    {
        NSLog(@"录音失败!");
    }
}


#pragma mark - 懒加载
/**
 *  获得录音机对象
 *
 *  @return 录音机对象
 */
-(AVAudioRecorder *)audioRecorder
{
    if (!_audioRecorder)
    {
        //创建录音文件保存路径
        NSURL *url = [NSURL fileURLWithPath:[self getSavePath]];
        //创建录音格式设置
        NSDictionary *setting=[self getAudioSetting];
        //创建录音机
        NSError *error=nil;
        _audioRecorder=[[AVAudioRecorder alloc] initWithURL:url settings:setting error:&error];
        _audioRecorder.delegate=self;
        _audioRecorder.meteringEnabled=YES;//如果要监控声波则必须设置为YES
        if (error) {
            NSLog(@"创建录音机对象时发生错误，错误信息：%@",error.localizedDescription);
            return nil;
        }
    }
    return _audioRecorder;
}

@end
