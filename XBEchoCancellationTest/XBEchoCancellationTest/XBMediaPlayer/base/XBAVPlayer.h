//
//  XBAVPlayer.h
//  XBAVPlayer
//
//  Created by xxb on 2017/6/22.
//  Copyright © 2017年 xxb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "XBAVPlayerConfig.h"
#import "XBResourceLoader.h"

@interface XBAVPlayer : UIView <XBLoaderDelegate>

@property (nonatomic, strong) XBResourceLoader *resourceLoader;//资源控制器，用于缓存item

@property (nonatomic,strong) AVPlayer *player;//播放器对象

@property (nonatomic,assign) NSTimeInterval lastTime; //记录上一次检测的时间，用于对比，检测当前播放的item是否卡顿了(用于记录暂停播放的时间)

@property (nonatomic,strong) NSArray *arr_urlStrs; //item地址数组，可以是本地路径，也可以是网络路径

@property (nonatomic,assign,readonly) NSInteger index; //当前播放第几个

@property (nonatomic,assign) CGFloat f_playingItemDuration; //正在播放的item总时长

@property (nonatomic,assign) BOOL b_autoPlayNext; //是否自动播放下一个

@property (nonatomic,assign) BOOL b_isPlaying; //是否在播放

@property (nonatomic,assign) CGFloat progressRate;//进度回调的频率，5则为每秒回调5次



@property (nonatomic,copy) PlaybackFinishedBlock bl_playbackFinish; //播放完成回调

@property (nonatomic,copy) PlayProgressBlock bl_playProgress; //播放进度回调

@property (nonatomic,copy) BufferBlock bl_bufferBlock; //缓冲数据回调

@property (nonatomic,copy) PlaySmoothStopBlock bl_smoothStop; //卡顿的回调

@property (nonatomic,copy) PlaySmoothStartBlock bl_smoothStart; //正常（恢复正常）播放的回调




#pragma mark - 控制

/**
 播放
 */
- (void)playWithErrorBlock:(XBAVPlayerErrorBlock)errorBlock;

/**
 恢复播放
 */
- (void)continuePlay;

/**
 暂停
 */
- (void)pause;

/**
 下一个
 */
- (void)next;

/**
 上一个
 */
- (void)previous;

/**
 指定播放第几个
 */
- (void)playIndex:(NSInteger)index errorBlock:(XBAVPlayerErrorBlock)errorBlock;

/**
 设置进度
 如果设置的进度超过item时长，则当前item直接结束
 */
- (void)seekToTime:(CGFloat)time;

/**
 释放播放器
 */
- (void)freePlayer;



#pragma mark - 子类继承
///屏幕方向改变了
- (void)deviceOrientationDidChanged:(NSInteger)orientation;

///播放卡住了（网络不好）
- (void)SmoothStopCurrentProgress:(NSTimeInterval)CurrentProgress totalProgress:(NSTimeInterval)totalProgress;

///播放重新开始
- (void)smoothNormalCurrentProgress:(NSTimeInterval)CurrentProgress totalProgress:(NSTimeInterval)totalProgress;

///当前缓冲到哪里了
- (void)totalBuffer:(CGFloat)totalBuffer;

///播放进度
- (void)playProgress:(CGFloat)progress current:(CGFloat)current total:(CGFloat)total;

///某个item播放结束后调用
- (void)playbackFinish;

///调用了play方法，并且可以播放（显示等待）
- (void)playFunSuccess;

///调用了play方法，并且不可播放（展示错误）
- (void)playFunFailure;

///item缓冲了一部分，可以播放了（隐藏等待）
- (void)readyToPlay;

///要播放第某个item出错
- (void)playIndexFaiulre:(NSInteger)index;


///播放项改变了,在 切换选集 到 播放新的播放项 之间调用
- (void)playItemDidChanged;

@end
