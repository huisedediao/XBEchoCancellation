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

typedef void (^XBEchoCancellation_bufferBlock)(AudioBuffer buffer);
typedef void (^XBEchoCancellation_playBlock)(void *mData,UInt32 inNumberFrames);

@interface XBEchoCancellation : NSObject

@property (nonatomic,assign) XBEchoCancellationStatus status;
@property (nonatomic,assign) AudioStreamBasicDescription streamFormat;

@property (nonatomic,copy) XBEchoCancellation_bufferBlock   bl_echoCancellation;
@property (nonatomic,copy) XBEchoCancellation_playBlock     bl_play;

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
