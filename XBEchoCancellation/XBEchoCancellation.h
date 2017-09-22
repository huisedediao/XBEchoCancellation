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

#define kRate (8000)
//#define kRate (44100)

typedef enum : NSUInteger {
    XBEchoCancellationRate_8k = 8000,
    XBEchoCancellationRate_20k = 20000,
    XBEchoCancellationRate_44k = 44100,
    XBEchoCancellationRate_96k = 96000
} XBEchoCancellationRate;

typedef enum : NSUInteger {
    XBEchoCancellationStatus_open,
    XBEchoCancellationStatus_close
} XBEchoCancellationStatus;

typedef void (^XBEchoCancellationBlock)(AudioBuffer buffer);

@interface XBEchoCancellation : NSObject

@property (nonatomic,assign) XBEchoCancellationStatus status;
@property (nonatomic,assign) AudioStreamBasicDescription streamFormat;

+ (instancetype)shared;
- (void)startWithBlock:(XBEchoCancellationBlock)bl_buffer;
- (void)stop;

@end
