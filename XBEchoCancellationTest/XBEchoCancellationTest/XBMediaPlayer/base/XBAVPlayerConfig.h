//
//  XBAVPlayerConfig.h
//  XBAVPlayer
//
//  Created by xxb on 2017/6/22.
//  Copyright © 2017年 xxb. All rights reserved.
//

#ifndef XBAVPlayerConfig_h
#define XBAVPlayerConfig_h

#import "XBAudioModeManager.h"

typedef enum : NSUInteger {
    XBAVPlayerErrorPlayIndexError, //要播放的序号错误
    XBAVPlayerErrorPrepareItemError //要播放的item出错，无法播放（url初始化item出错）
} XBAVPlayerError;

@class XBAVPlayer;
@class XBVideoPlayer;

//播放完一个视频后的回调
typedef void (^PlaybackFinishedBlock)(XBAVPlayer *player);

//进度回调
typedef void (^PlayProgressBlock)(XBAVPlayer *player, CGFloat progress, CGFloat current ,CGFloat total);

//视频卡顿的回调
typedef void (^PlaySmoothStopBlock)(XBAVPlayer *player, NSTimeInterval currentProgress, NSTimeInterval totalProgress);

//视频正常（恢复正常）的回调
typedef void (^PlaySmoothStartBlock)(XBAVPlayer *player, NSTimeInterval currentProgress, NSTimeInterval totalProgress);

//竖直放置的布局
typedef void (^LayoutBlock_vertical)(XBAVPlayer *player);

//水平放置时的布局
typedef void (^LayoutBlock_horizontal)(XBAVPlayer *player);

//返回一个等待的view
typedef UIView* (^WaitViewBlock)(XBAVPlayer *player);

/**
 totalBuffer ：当前缓冲到哪了
 */
typedef void (^BufferBlock)(XBAVPlayer *player, CGFloat totalBuffer);

//出错的block
typedef void (^XBAVPlayerErrorBlock)(XBAVPlayer *player, XBAVPlayerError xbError);


//视频播放器创建UI的block，只会执行一次（用这个block，避免创建的图层被player的palyerLayer遮挡）
typedef void (^VideoPlayerBuildUIBlock)(XBVideoPlayer *player);

//播放器调用play方法，并且当前item可以播放时的回调 （用于显示等待界面）
//typedef void (^PlayFunSuccessBlock)(XBAVPlayer *player);

//播放器调用play方法时，当前item无法播放的回调 （用于提示错误）
//typedef void (^PlayFunFailureBlock)(XBAVPlayer *player);

//已经可以播放了（用于隐藏等待界面）
//typedef void (^ReadyToPlayBlock)(XBAVPlayer *player);



//block weak属性化self宏
#define WEAK_SELF __typeof(self) __weak weakSelf = self;

//屏幕宽高
#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height

#endif /* XBAVPlayerConfig_h */
