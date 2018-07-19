//
//  XBResourceLoader.h
//  XBMediaPlayer
//
//  Created by xxb on 2017/8/9.
//  Copyright © 2017年 xxb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "XBRequestTask.h"

#define MimeType @"video/mp4"

@class XBResourceLoader;
@protocol XBLoaderDelegate <NSObject>

@required
- (void)loader:(XBResourceLoader *)loader cacheProgress:(CGFloat)progress;

@optional
- (void)loader:(XBResourceLoader *)loader failLoadingWithError:(NSError *)error;

@end

@interface XBResourceLoader : NSObject<AVAssetResourceLoaderDelegate,XBRequestTaskDelegate>

@property (nonatomic, weak) id<XBLoaderDelegate> delegate;
@property (atomic, assign) BOOL seekRequired; //Seek标识
@property (nonatomic, assign) BOOL cacheFinished;

- (void)stopLoading;

@end


