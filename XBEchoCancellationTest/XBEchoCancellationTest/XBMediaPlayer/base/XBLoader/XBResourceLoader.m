//
//  XBResourceLoader.m
//  XBMediaPlayer
//
//  Created by xxb on 2017/8/9.
//  Copyright © 2017年 xxb. All rights reserved.
//

#import "XBResourceLoader.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "XBAVFileHandle.h"
#import "XBDataTaskManager.h"
#import "NSURL+XBLoader.h"

@interface XBResourceLoader ()

@property (nonatomic, strong) NSMutableArray * requestList;
@property (nonatomic, strong) XBRequestTask * requestTask;

@end

@implementation XBResourceLoader

- (instancetype)init
{
    if (self = [super init])
    {
        self.requestList = [NSMutableArray array];
    }
    return self;
}

- (void)stopLoading
{
    [self.requestTask stop];
}

#pragma mark - AVAssetResourceLoaderDelegate
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSLog(@"WaitingLoadingRequest < requestedOffset = %lld, currentOffset = %lld, requestedLength = %ld >", loadingRequest.dataRequest.requestedOffset, loadingRequest.dataRequest.currentOffset, loadingRequest.dataRequest.requestedLength);
    [self addLoadingRequest:loadingRequest];
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSLog(@"CancelLoadingRequest  < requestedOffset = %lld, currentOffset = %lld, requestedLength = %ld >", loadingRequest.dataRequest.requestedOffset, loadingRequest.dataRequest.currentOffset, loadingRequest.dataRequest.requestedLength);
    [self removeLoadingRequest:loadingRequest];
}

#pragma mark - XBRequestTaskDelegate
- (void)requestTaskDidUpdateCache
{
    [self processRequestList];
    if (self.delegate && [self.delegate respondsToSelector:@selector(loader:cacheProgress:)])
    {
        CGFloat cacheProgress = (CGFloat)self.requestTask.cacheLength / (self.requestTask.fileLength - self.requestTask.requestOffset);
        [self.delegate loader:self cacheProgress:cacheProgress];
    }
}

- (void)requestTaskDidFinishLoadingWithCache:(BOOL)cache
{
    self.cacheFinished = cache;
}

- (void)requestTaskDidFailWithError:(NSError *)error
{
    //加载数据错误的处理
    if (self.delegate && [self.delegate respondsToSelector:@selector(loader:failLoadingWithError:)])
    {
        [self.delegate loader:self failLoadingWithError:error];
    }
}

#pragma mark - 处理LoadingRequest
- (void)addLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    [self.requestList addObject:loadingRequest];
    @synchronized(self)
    {
        if (self.requestTask == nil)
        {
            XBAVFileHandle *fileHandle = [XBAVFileHandle shared];
            NSString *filePath = [fileHandle pathAppendByHomeDirectory:fileHandle.dicM_tempFilePath[[loadingRequest.request.URL originalSchemeURL]]];
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])//临时文件存在再判断任务是否存在，有任务没有临时文件设置self.requestTask没有意义
            {
                XBRequestTask *task = nil;
                
                //判断是否存在相同url的任务，有，直接取，没有，创建
                for (XBRequestTask *taskTemp in [XBDataTaskManager shared].arrM_taskList)
                {
                    NSURL *url = loadingRequest.request.URL;
                    if ([taskTemp.requestURL.absoluteString isEqualToString:url.absoluteString])
                    {
                        task = taskTemp;
                        break;
                    }
                }
                if (task.cache == NO)//说明是拖动过的，保存的数据不是从头开始的，直接删除
                {
                    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                }
                else
                {
                    self.requestTask = task;
                    self.requestTask.delegate = self;
                    [self.requestTask start];
                    self.seekRequired = NO;
                }
            }
            else
            {
                fileHandle.dicM_tempFilePath[[loadingRequest.request.URL originalSchemeURL]] = nil;
            }
        }
        
        if (self.requestTask)
        {
            NSLog(@"self.requestTask.requestOffset:%zd, self.requestTask.cacheLength:%zd",self.requestTask.requestOffset,self.requestTask.cacheLength);
            if (loadingRequest.dataRequest.requestedOffset >= self.requestTask.requestOffset &&
                loadingRequest.dataRequest.requestedOffset <= self.requestTask.requestOffset + self.requestTask.cacheLength)
            {
                //数据已经缓存，则直接完成
                NSLog(@"数据已经缓存，则直接完成");
                [self processRequestList];
            }
            else
            {
                //数据还没缓存，则等待数据下载；如果是Seek操作，则重新请求
                if (self.seekRequired)
                {
                    [[XBAVFileHandle shared] deleteTempFileForTask:self.requestTask];
                    NSLog(@"Seek操作，则重新请求");
                    [self newTaskWithLoadingRequest:loadingRequest cache:NO];
                }
            }
        }
        else
        {
            [self newTaskWithLoadingRequest:loadingRequest cache:YES];
        }
    }
}

- (void)newTaskWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest cache:(BOOL)cache
{
    XBRequestTask *task = nil;
    
    //判断是否存在相同url的任务，有，直接取，没有，创建
    for (XBRequestTask *taskTemp in [XBDataTaskManager shared].arrM_taskList)
    {
        NSURL *url = loadingRequest.request.URL;
        if ([taskTemp.requestURL.absoluteString isEqualToString:url.absoluteString])
        {
            task = taskTemp;
            break;
        }
    }
    
    if (cache == NO)
    {
        //说明是拖动的，从管理类的数组中找到任务，停止，然后移除，重新创建任务，添加到数组  //新任务
        //这种情况下一定存在task，把task的fileLength赋值给新任务,用于在任务的start时设置range
        
        NSLog(@"newTaskWithLoadingRequest-->>seek");
        NSLog(@"%@",task);
        
        [task stop];
        [[XBDataTaskManager shared] removeDataTask:task];
        
        [self.requestTask stop];
        self.requestTask = [[XBRequestTask alloc] init];
        self.requestTask.requestURL = loadingRequest.request.URL;
        self.requestTask.requestOffset = loadingRequest.dataRequest.requestedOffset;
        self.requestTask.fileLength = task.fileLength;
        self.requestTask.cache = NO;
        [[XBDataTaskManager shared] addDataTask:self.requestTask];
    }
    else
    {
        if (task)
        {
            [self.requestTask stop];
            self.requestTask = task;
            task.cache = YES;
        }
        else   //新任务
        {
            [self.requestTask stop];
            self.requestTask = [[XBRequestTask alloc]init];
            self.requestTask.requestURL = loadingRequest.request.URL;
            self.requestTask.cache = YES;
            [[XBDataTaskManager shared] addDataTask:self.requestTask];
        }
    }
    
    self.requestTask.delegate = self;
    [self.requestTask start];
    self.seekRequired = NO;
}

- (void)removeLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    [self.requestList removeObject:loadingRequest];
}

- (void)processRequestList
{
    NSMutableArray * finishRequestList = [NSMutableArray array];
    for (AVAssetResourceLoadingRequest * loadingRequest in self.requestList)
    {
        if ([self finishLoadingWithLoadingRequest:loadingRequest])
        {
            [finishRequestList addObject:loadingRequest];
        }
    }
    [self.requestList removeObjectsInArray:finishRequestList];
}

- (BOOL)finishLoadingWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    //填充信息
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(MimeType), NULL);
    loadingRequest.contentInformationRequest.contentType = CFBridgingRelease(contentType);
    loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
    loadingRequest.contentInformationRequest.contentLength = self.requestTask.fileLength;
    
    //读文件，填充数据
    NSUInteger cacheLength = self.requestTask.cacheLength;
    //loadingRequest.dataRequest.requestedOffset 代表请求的数据开始的位置
    NSUInteger requestedOffset = loadingRequest.dataRequest.requestedOffset;
    if (loadingRequest.dataRequest.currentOffset != 0) {
        requestedOffset = loadingRequest.dataRequest.currentOffset;
    }
    //loadingRequest.dataRequest.currentOffset 代表已经请求数据的结尾的位置，比如请求的起始位置为70，长度是100，当前已经相应的数据到了120，则剩余需要读取的长度为 100 - （120 - 70）
    NSUInteger canReadLength = cacheLength - (requestedOffset - loadingRequest.dataRequest.requestedOffset);
    //这里和请求的长度对比，因为多个请求，都是同一个url，缓存的数据的数据量可能大于该请求所需
    NSUInteger respondLength = MIN(canReadLength, loadingRequest.dataRequest.requestedLength);
    
    //这里的offset：（requestedOffset - self.requestTask.requestOffset）很关键
    //如果是正常加载，self.requestTask.requestOffset 为 0 ，请求的起始offset为requestedOffset
    //如果是拖动的，（requestedOffset - self.requestTask.requestOffset）为相对起始位置，比如开始下载的位置（self.requestTask.requestOffset）为100，需要返回的数据的起始位置为120，则从文件读取的起始位置为20
    NSData *data = [[XBAVFileHandle shared] readTempFileDataWithOffset:(requestedOffset - self.requestTask.requestOffset) length:respondLength forTask:self.requestTask];
    [loadingRequest.dataRequest respondWithData:data];
    
    //如果完全响应了所需要的数据，则完成
    NSUInteger nowendOffset = requestedOffset + canReadLength;
    NSUInteger reqEndOffset = loadingRequest.dataRequest.requestedOffset + loadingRequest.dataRequest.requestedLength;
    if (nowendOffset >= reqEndOffset) {
        [loadingRequest finishLoading];
        return YES;
    }
    return NO;
}

@end

