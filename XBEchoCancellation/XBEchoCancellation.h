//
//  XBEchoCancellation.h
//  iOSEchoCancellation
//
//  Created by xxb on 2017/8/25.
//  Copyright © 2017年 xxb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

typedef enum : NSUInteger {
    XBEchoCancellationRate_8k = 8000,
    XBEchoCancellationRate_20k = 20000,
    XBEchoCancellationRate_44k = 44100,
    XBEchoCancellationRate_96k = 96000
} XBEchoCancellationRate;

#define kRate (XBEchoCancellationRate_8k) //采样率
#define kChannels   (1)//声道数
#define kBits       (16)//位数


typedef enum : NSUInteger {
    XBEchoCancellationStatus_open,
    XBEchoCancellationStatus_close
} XBEchoCancellationStatus;

typedef void (^XBEchoCancellation_inputBlock)(AudioBuffer buffer);
typedef void (^XBEchoCancellation_outputBlock)(AudioBuffer buffer,UInt32 inNumberFrames);

@interface XBEchoCancellation : NSObject

@property (nonatomic,assign,readonly) XBEchoCancellationStatus status;
@property (nonatomic,assign,readonly) AudioStreamBasicDescription streamFormat;
///录音的回调，回调的参数为从麦克风采集到的声音
@property (nonatomic,copy) XBEchoCancellation_inputBlock bl_input;
///播放的回调，回调的参数 buffer 为要向播放设备（扬声器、耳机、听筒等）传的数据，在回调里把数据传给 buffer
@property (nonatomic,copy) XBEchoCancellation_outputBlock bl_output;

+ (instancetype)shared;

- (void)startInput;
- (void)stopInput;

- (void)startOutput;
- (void)stopOutput;

- (void)openEchoCancellation;
- (void)closeEchoCancellation;

///开启服务，需要另外去开启 input 或者 output 功能
- (void)startService;
///停止所有功能（包括录音和播放）
- (void)stop;

@end
