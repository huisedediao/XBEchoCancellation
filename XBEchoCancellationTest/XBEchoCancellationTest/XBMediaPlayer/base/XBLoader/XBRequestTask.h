//
//  XBRequestTask.h
//  XBMediaPlayer
//
//  Created by xxb on 2017/8/9.
//  Copyright © 2017年 xxb. All rights reserved.
//

#import <Foundation/Foundation.h>

#define RequestTimeout 20.0

@class XBRequestTask;

typedef void (^ProgressBlock)(XBRequestTask *task);

@protocol XBRequestTaskDelegate <NSObject>

@required
- (void)requestTaskDidUpdateCache; //更新缓冲进度代理方法

@optional
- (void)requestTaskDidReceiveResponse;
- (void)requestTaskDidFinishLoadingWithCache:(BOOL)cache;
- (void)requestTaskDidFailWithError:(NSError *)error;

@end

@interface XBRequestTask : NSObject

//根据requestOffset，fileLength，cacheLength 可以算出所有需要的信息

@property (nonatomic, weak) id<XBRequestTaskDelegate> delegate;
@property (nonatomic, strong) NSURL * requestURL; //请求网址
@property (nonatomic, assign) NSUInteger requestOffset; //请求起始位置
@property (nonatomic, assign) NSUInteger fileLength; //文件长度
@property (nonatomic, assign) NSUInteger cacheLength; //缓冲长度
@property (nonatomic, assign) BOOL cache; //是否缓存文件
@property (nonatomic, assign, readonly) double progress;
@property (nonatomic, assign, readonly) BOOL complete;
@property (nonatomic, copy) NSString *str_name;//保存的名字
@property (nonatomic, copy) ProgressBlock bl_progress;
/**
 *  开始请求
 */
- (void)start;

- (void)stop;

@end
