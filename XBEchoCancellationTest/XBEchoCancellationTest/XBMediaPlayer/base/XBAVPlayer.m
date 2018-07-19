//
//  XBAVPlayer.m
//  XBAVPlayer
//
//  Created by xxb on 2017/6/22.
//  Copyright © 2017年 xxb. All rights reserved.
//

#import "XBAVPlayer.h"
#import "XBAVFileHandle.h"

#define IOS_VERSION  ([[[UIDevice currentDevice] systemVersion] floatValue])

@interface XBAVPlayer ()

@property (nonatomic,strong) AVPlayerItem *prepareItem;//player即将播放的item
@property (nonatomic,strong) NSObject *playerObserver;
@property (nonatomic,copy) XBAVPlayerErrorBlock playErrorBlock;//记录播放失败的block
@property (nonatomic,copy) XBAVPlayerErrorBlock playIndexErrorBlock;//记录播放第某个item失败的block
@property (nonatomic,strong) NSTimer *timer; //定时器，用于检测item是否卡顿了

@end

@implementation XBAVPlayer

#pragma mark - 生命周期
-(instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self initParams];
        [self addNoticeAtInit_base];
    }
    return self;
}

- (void)initParams
{
    self.progressRate = 5.0;
}

- (void)removePlayerTimeObserver
{
    [_player removeTimeObserver:self.playerObserver];
}

-(void)dealloc
{
    [self removeObserverFromPlayerItem:_player.currentItem];
    [self removeNotification];
    [self removeTime];
    NSLog(@"XBAVPlayer销毁");
}

#pragma mark - 其他方法
-(void)addTime
{
    if (self.timer == nil)
    {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkSmooth) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
}
-(void)removeTime
{
    if (self.timer)
    {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)deviceOrientationDidChange:(NSNotification *)notification
{
    NSInteger stateNoworientation = (NSInteger)((UIDevice *)[notification object]).orientation;
    NSLog(@"stateNoworientation:%zd",stateNoworientation);
    //1竖屏,正常
    //3左边在下
    //4右边在下
    //2竖屏，顶边在下
    [self deviceOrientationDidChanged:stateNoworientation];
}

#pragma mark - 通知
/**
 *  添加播放器通知
 */
-(void)addNotification_base
{
    //给AVPlayerItem添加播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}

-(void)addNoticeAtInit_base
{
    //添加通知获取设备发生旋转时的相关信息
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

-(void)removeNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/**
 *  播放完成通知
 *
 *  @param notification 通知对象
 */
-(void)playbackFinished:(NSNotification *)notification
{
    NSLog(@"item播放完成.");
    if (self.bl_playbackFinish)
    {
        WEAK_SELF
        dispatch_async(dispatch_get_main_queue(), ^{
            [self playbackFinish];
            self.bl_playbackFinish(weakSelf);
        });
    }
    if (self.b_autoPlayNext)
    {
        [self next];
    }
    self.b_isPlaying = NO;
}

#pragma mark - 监控
/**
 *  给播放器添加进度更新
 */
-(void)addProgressObserver
{
    WEAK_SELF
    //这里设置每秒执行一次
    // CMTimeMake(time, timeScale)， time / timeScale 是秒
    self.playerObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, self.progressRate) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current = CMTimeGetSeconds(time);
        float total = CMTimeGetSeconds([weakSelf.player.currentItem duration]);
        //NSLog(@"当前已经播放%.2fs.",current);
        NSLog(@"addProgressObserver:\rcurrent:%f\rtotal:%f",current,total);
        if (current)
        {
            CGFloat progress = (current/total);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf.bl_playProgress)
                {
                    weakSelf.bl_playProgress(weakSelf, progress, current, total);
                }
                [weakSelf playProgress:progress current:current total:total];
            });
        }
    }];
}

/**
 *  给AVPlayerItem添加监控
 *
 *  @param playerItem AVPlayerItem对象
 */
-(void)addObserverToPlayerItem:(AVPlayerItem *)playerItem
{
    //监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监控网络加载情况属性
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];

}

-(void)removeObserverFromPlayerItem:(AVPlayerItem *)playerItem
{
    [playerItem removeObserver:self forKeyPath:@"status"];
    [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
}

/**
 *  通过KVO监控播放器状态
 *
 *  @param keyPath 监控属性
 *  @param object  监视器
 *  @param change  状态改变
 *  @param context 上下文
 */
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    AVPlayerItem *playerItem = object;
    if ([keyPath isEqualToString:@"status"])
    {
        AVPlayerStatus status = self.player.status;
        
        if(status == AVPlayerStatusReadyToPlay)
        {
            self.f_playingItemDuration = CMTimeGetSeconds(playerItem.duration);
            //去除等待
            dispatch_async(dispatch_get_main_queue(), ^{
                //给子类
                [self readyToPlay];
            });
        }
        else
        {
            NSLog(@"AVPlayerStatusFailed");
        }
    }
    else if([keyPath isEqualToString:@"loadedTimeRanges"])
    {
        NSArray *array=playerItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓冲时间范围
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;//缓冲总长度
        
        if (self.bl_bufferBlock)
        {
            WEAK_SELF
            dispatch_async(dispatch_get_main_queue(), ^{
                [self totalBuffer:totalBuffer];
                self.bl_bufferBlock(weakSelf, totalBuffer);
            });
        }
        NSLog(@"共缓冲：%.2f",totalBuffer);
    }
    else if ([keyPath isEqualToString:@"playbackBufferEmpty"])//监听播放器在缓冲数据的状态
    {
        NSLog(@"缓冲不足暂停了");
    }
    else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"])
    {
        NSLog(@"缓冲达到可播放程度了");
        
        //由于 AVPlayer 缓存不足就会自动暂停，所以缓存充足了需要手动播放，才能继续播放
        if (self.b_isPlaying)
        {
            [self continuePlay];
        }
    }
}

#pragma mark - 其他方法

//检查item是否流畅
- (void)checkSmooth
{
    NSTimeInterval current = CMTimeGetSeconds(self.player.currentTime);
    NSTimeInterval total = CMTimeGetSeconds(self.player.currentItem.duration);
    
    //NSLog(@"current:%f,total:%f",current,self.lastTime);
    if (self.b_isPlaying)
    {
        if (current != self.lastTime)//正常的
        {
            NSLog(@"checkSmooth:正常的");
            dispatch_async(dispatch_get_main_queue(), ^{
                //给外部
                if (self.bl_smoothStart)
                {
                    WEAK_SELF
                    self.bl_smoothStart(weakSelf, current, total);
                }
                //子类继承
                [self smoothNormalCurrentProgress:current totalProgress:total];
            });
            self.lastTime = current;
        }
        else //卡顿了
        {
            
            NSLog(@"checkSmooth:卡顿了");
            dispatch_async(dispatch_get_main_queue(), ^{
                //给外部
                if (self.bl_smoothStop)
                {
                    WEAK_SELF
                    self.bl_smoothStop(weakSelf, current, total);
                }
                //子类继承
                [self SmoothStopCurrentProgress:current totalProgress:total];
            });
        }
    }
}

- (void)freePlayer
{
    [self removePlayerTimeObserver];
    _playerObserver = nil;
    [_player pause];
    [self removeTime];
    
    //    [self.player.currentItem cancelPendingSeeks];
    //    [self.player.currentItem.asset cancelLoading];
}

/**
 *  切换选集
 */
-(void)changePlayItem
{
    NSLog(@"XBAVPlayer->changePlayItem->当前线程%@",[NSThread currentThread]);
    [_player pause];//这里不能用点语法，因为涉及到懒加载，创建player的时候会用到item，如果用到点语法，这行代码之后又调用了self.play = nil,但是之前self.play指向的player没有释放，就会报：reason: 'An AVPlayerItem cannot be associated with more than one instance of AVPlayer' 错误
    self.b_isPlaying = NO;
    [self removeTime];
    [self removeNotification];
    [self removeObserverFromPlayerItem:_player.currentItem];//这里不能用点语法,理由同上
    [self removePlayerTimeObserver];
    _player = nil; //这里置为nil，是因为：githup上ZFPlayer 作者表示在iOS9后，AVPlayer的replaceCurrentItemWithPlayerItem方法在切换视频时底层会调用信号量等待然后导致当前线程卡顿，如果在UITableViewCell中切换视频播放使用这个方法，会导致当前线程冻结几秒钟。会卡死

    [self addNoticeAtInit_base];
    
    //给子类
    [self playItemDidChanged];
    
    [self playWithErrorBlock:self.playErrorBlock];
}

- (void)setPreparPlayItem
{
    AVPlayerItem *tempItem = [self getPlayItem:self.index];
    if (tempItem)
    {
        self.prepareItem = tempItem;
    }
}

/**
 *  根据item索引取得AVPlayerItem对象
 *
 *  @param videoIndex item顺序索引
 *
 *  @return AVPlayerItem对象
 */
-(AVPlayerItem *)getPlayItem:(NSInteger)videoIndex
{
    NSString *urlStr = self.arr_urlStrs[videoIndex];
    BOOL isLocalFile = [[NSFileManager defaultManager] fileExistsAtPath:urlStr];
    if (isLocalFile || IOS_VERSION < 7.0) //本地或者ios7以下，直接播放
    {
        NSURL *sourceMovieUrl = [NSURL fileURLWithPath:urlStr];
        AVAsset *movieAsset = [AVURLAsset URLAssetWithURL:sourceMovieUrl options:nil];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
        return playerItem;
    }
    else
    {
        AVPlayerItem *playerItem = nil;
        NSURL *url = [NSURL URLWithString:urlStr];
        
        //有缓存播放缓存文件
        //        NSString * cacheFilePath = [SUFileHandle cacheFileExistsWithURL:url];
        NSString * cacheFilePath = [[XBAVFileHandle shared] fileExistsWithURL:url];
        if (cacheFilePath)
        {
            NSURL * url = [NSURL fileURLWithPath:cacheFilePath];
            playerItem = [AVPlayerItem playerItemWithURL:url];
            NSLog(@"有缓存，播放缓存文件");
        }
        else
        {
            self.resourceLoader = [[XBResourceLoader alloc]init];
            self.resourceLoader.delegate = self;
            AVURLAsset * asset = [AVURLAsset URLAssetWithURL:[url customSchemeURL] options:nil];
            [asset.resourceLoader setDelegate:self.resourceLoader queue:dispatch_get_main_queue()];
            playerItem = [AVPlayerItem playerItemWithAsset:asset];
            NSLog(@"没有缓存，开始请求数据");
        }
        return playerItem;
    }
}

#pragma mark - XBLoaderDelegate
- (void)loader:(XBResourceLoader *)loader cacheProgress:(CGFloat)progress
{
    NSLog(@"缓冲进度%f",progress);
}
- (void)loader:(XBResourceLoader *)loader failLoadingWithError:(NSError *)error
{
    NSLog(@"下载出错，错误码：%zd",error.code);
    
    NSString *str = nil;
    switch (error.code)
    {
        case -1001:
            str = @"请求超时";
            break;
        case -1003:
        case -1004:
            str = @"服务器错误";
            break;
        case -1005:
            str = @"网络中断";
            break;
        case -1009:
            str = @"无网络连接";
            break;
            
        default:
            str = [NSString stringWithFormat:@"%@", @"(_errorCode)"];
            break;
    }
}

#pragma mark - 懒加载
/**
 *  初始化播放器
 *
 *  @return 播放器对象
 */
-(AVPlayer *)player
{
    if (_player == nil)
    {
        _player = [AVPlayer playerWithPlayerItem:self.prepareItem];
        [self addNotification_base];
        [self addProgressObserver];
        [self addObserverToPlayerItem:self.prepareItem];
    }
    return _player;
}

#pragma mark - 方法重写

-(void)setF_playingItemDuration:(CGFloat)f_playingItemDuration
{
    _f_playingItemDuration = f_playingItemDuration;
    NSLog(@"总长度：%f",f_playingItemDuration);
}

-(void)setArr_urlStrs:(NSArray *)arr_urlStrs
{
    _arr_urlStrs = arr_urlStrs;
    
    self.index = 0;
}

-(void)setIndex:(NSInteger)index
{
    _index = index;
    
    [self setPreparPlayItem];
}

#pragma mark - 子类继承
- (void)deviceOrientationDidChanged:(NSInteger)orientation
{

}
//播放卡住了（网络不好）
- (void)SmoothStopCurrentProgress:(NSTimeInterval)CurrentProgress totalProgress:(NSTimeInterval)totalProgress
{
    
}
//播放重新开始
- (void)smoothNormalCurrentProgress:(NSTimeInterval)CurrentProgress totalProgress:(NSTimeInterval)totalProgress
{
    
}
//当前缓冲到哪里了
- (void)totalBuffer:(CGFloat)totalBuffer
{
    
}
//播放进度
- (void)playProgress:(CGFloat)progress current:(CGFloat)current total:(CGFloat)total
{
    
}
//某个item播放结束后调用
- (void)playbackFinish
{
    
}
//调用了play方法，并且可以播放（显示等待）
- (void)playFunSuccess
{
    
}
//调用了play方法，并且不可播放（展示错误）
- (void)playFunFailure
{
    
}
//item缓冲了一部分，可以播放了（隐藏等待）
- (void)readyToPlay
{
    
}
//要播放第某个item出错
- (void)playIndexFaiulre:(NSInteger)index
{
    
}
//播放项改变了
- (void)playItemDidChanged
{

}

#pragma mark - 控制
- (void)playWithErrorBlock:(XBAVPlayerErrorBlock)errorBlock//播放
{
    NSLog(@"XBAVPlayer->playWithErrorBlock->当前线程%@",[NSThread currentThread]);

    if (self.prepareItem)
    {
        NSLog(@"播放进程%@",[NSThread currentThread]);
        [self.player play];
        dispatch_async(dispatch_get_main_queue(), ^{
            //等待，给子类
            [self playFunSuccess];
        });
        [self addTime];
        self.b_isPlaying = YES;
    }
    else
    {
        self.playErrorBlock = errorBlock;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //给外部
            if (errorBlock)
            {
                WEAK_SELF
                errorBlock(weakSelf,XBAVPlayerErrorPrepareItemError);
            }
            //给子类
            [self playFunFailure];
        });
    }
}

- (void)continuePlay
{
    [self.player play];
    self.b_isPlaying = YES;
}

- (void)pause //暂停
{
    [self.player pause];
    self.b_isPlaying = NO;
}

- (void)next //下一个
{
    NSInteger tempIndex = self.index + 1;
    if (tempIndex > self.arr_urlStrs.count - 1)
    {
        self.index = 0;
    }
    else
    {
        self.index = tempIndex;
    }
    
    [self changePlayItem];
}

- (void)previous //上一个
{
    NSInteger tempIndex = self.index - 1;
    if (tempIndex < 0)
    {
        self.index = self.arr_urlStrs.count - 1;
    }
    else
    {
        self.index = tempIndex;
    }
    [self changePlayItem];
}

- (void)playIndex:(NSInteger)index errorBlock:(XBAVPlayerErrorBlock)errorBlock //指定播放第几个
{
    if (index <= self.arr_urlStrs.count - 1 && index > -1)
    {
        self.index = index;
        [self changePlayItem];
    }
    else
    {
        self.playIndexErrorBlock = errorBlock;
        dispatch_async(dispatch_get_main_queue(), ^{
            //提示序号不合法，给外部
            if (errorBlock)
            {
                WEAK_SELF
                errorBlock(weakSelf,XBAVPlayerErrorPlayIndexError);
            }
            //给子类
            [self playIndexFaiulre:index];
        });
    }
}

- (void)seekToTime:(CGFloat)time //设置进度
{
    if (self.player.status == AVPlayerStatusReadyToPlay) {
        
        self.resourceLoader.seekRequired = YES;
        CMTime cmTime = CMTimeMakeWithSeconds(time, 1 * NSEC_PER_USEC);
        @try
        {
            [self.player seekToTime:cmTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished){
                if (finished)
                {
                    [self.player play];
                    NSLog(@"拖动完成");
                }
                else
                {
                    NSLog(@"不知道什么鬼，是失败吗");
                }
            }];
        }
        @catch (NSException *exception)
        {
            [self.player play];
        }
    }
    else
    {
        NSLog(@"palyer还没准备好播放，不能拖动");
    }
}
@end
