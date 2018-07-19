//
//  XBAudioRecorder.h
//  XBMediaPlayer
//
//  Created by xxb on 2017/6/24.
//  Copyright © 2017年 xxb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface XBAudioRecorder : NSObject

+ (instancetype)shared;

-(NSString *)getSavePath;

///开始全新的录音
- (void)record;
///暂停
- (void)pause;
///恢复录音，在之前的基础上追加
- (void)resume;
///停止录音
- (void)stop;

/// 声音大小 以百分比显示
- (CGFloat)volumePow;

@end
