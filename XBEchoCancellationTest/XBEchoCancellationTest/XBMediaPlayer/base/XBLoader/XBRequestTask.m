//
//  XBRequestTask.m
//  XBMediaPlayer
//
//  Created by xxb on 2017/8/9.
//  Copyright © 2017年 xxb. All rights reserved.
//

#import "XBRequestTask.h"
#import "XBAVFileHandle.h"
#import "NSURL+XBLoader.h"
#import "XBDataTaskManager.h"

#define WEAKSELF typeof(self) __weak weakSelf = self;

#define key_requestURL      @"key_requestURL"
#define key_requestOffset   @"key_requestOffset"
#define key_fileLength      @"key_fileLength"
#define key_cacheLength     @"key_cacheLength"
#define key_cache           @"key_cache"
#define key_str_name        @"key_str_name"

@interface XBRequestTask ()<NSURLConnectionDataDelegate, NSURLSessionDataDelegate, NSCoding>

@property (nonatomic, strong) NSURLSession * session;               //会话对象
@property (nonatomic, strong) NSURLSessionDataTask * task;          //任务
@property (nonatomic, assign ,readonly) BOOL cancel;                //是否取消请求

@end

@implementation XBRequestTask

- (instancetype)init
{
    if (self = [super init])
    {
        [[XBAVFileHandle shared] deleteTempFileForTask:self];
        _cancel = YES;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        _requestURL = [aDecoder decodeObjectForKey:key_requestURL];
        _requestOffset = [aDecoder decodeInt64ForKey:key_requestOffset];
        _fileLength = [aDecoder decodeInt64ForKey:key_fileLength];
        _cacheLength = [aDecoder decodeInt64ForKey:key_cacheLength];
        _cache = [aDecoder decodeBoolForKey:key_cache];
        _str_name = [aDecoder decodeObjectForKey:key_str_name];
        _cancel = YES;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_requestURL forKey:key_requestURL];
    [aCoder encodeInt64:_requestOffset forKey:key_requestOffset];
    [aCoder encodeInt64:_fileLength forKey:key_fileLength];
    [aCoder encodeInt64:_cacheLength forKey:key_cacheLength];
    [aCoder encodeBool:_cache forKey:key_cache];
    [aCoder encodeObject:_str_name forKey:key_str_name];
}

#pragma mark - 方法重写
- (void)setRequestURL:(NSURL *)requestURL
{
    _requestURL = requestURL;
    [[XBAVFileHandle shared] createTempFileForTask:self];
}
- (void)setStr_name:(NSString *)str_name
{
    NSString *fileSavePath = [XBAVFileHandle shared].dicM_fileSavePath[[self.requestURL originalSchemeURL]];
    if (fileSavePath)
    {
        NSFileManager * manager = [NSFileManager defaultManager];
        if ([manager fileExistsAtPath:fileSavePath])
        {
            NSString * saveFolderPath = [NSString saveFolderPath];
            if (![manager fileExistsAtPath:saveFolderPath])
            {
                [manager createDirectoryAtPath:saveFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            NSString * newPath = [NSString stringWithFormat:@"%@/%@", saveFolderPath, str_name.length ? str_name : self.requestURL.absoluteString.lastPathComponent];
            [manager moveItemAtPath:fileSavePath toPath:newPath error:nil];
            [XBAVFileHandle shared].dicM_fileSavePath[[self.requestURL originalSchemeURL]] = newPath;
            [NSKeyedArchiver archiveRootObject:[XBAVFileHandle shared] toFile:fileSavePathDicSavePath];
        }
        else
        {
            [XBAVFileHandle shared].dicM_fileSavePath[[self.requestURL originalSchemeURL]] = nil;
        }
    }
    _str_name = str_name;
}
- (double)progress
{
    return 1.0 * self.cacheLength / self.fileLength;
}
- (BOOL)complete
{
    return self.cacheLength >= self.fileLength;
}

#pragma mark - 控制
- (void)start
{
    if (_cancel == NO)
    {
        return;
    }
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[self.requestURL originalSchemeURL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:RequestTimeout];
    if (self.cache == NO)
    {
        //说明是拖动的
        [request addValue:[NSString stringWithFormat:@"bytes=%ld-%ld", self.requestOffset, self.fileLength - 1] forHTTPHeaderField:@"Range"];
    }
    else
    {
        //未完成的任务继续的
        if (self.cacheLength > 0)
        {
            if (self.cacheLength == self.fileLength)//说明缓存文件夹中存在已经缓存好的文件，直接复制到文件存储文件夹
            {
                [[XBAVFileHandle shared] saveTempFileWithTask:self];
                return;
            }
            else
            {
                [request addValue:[NSString stringWithFormat:@"bytes=%ld-%ld", self.cacheLength - 1, self.fileLength - 1] forHTTPHeaderField:@"Range"];
            }
        }
    }
    self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    self.task = [self.session dataTaskWithRequest:request];
    [self.task resume];
    _cancel = NO;
}

- (void)stop
{
    _cancel = YES;
    self.delegate = nil;
    [self.task cancel];
    [self.session invalidateAndCancel];
}

- (void)deleteTempFile
{
    //从管理类的数组中移除任务
    //    NSURL *key = [self.requestURL originalSchemeURL];
    //    NSString *tempFilePath = [XBAVFileHandle shared].dicM_tempFilePath[key];
    //    [[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:nil];
    [[XBDataTaskManager shared] removeDataTask:self];
}

#pragma mark - NSURLSessionDataDelegate
//服务器响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    if (self.cancel) return;
    NSLog(@"response: %@",response);
    completionHandler(NSURLSessionResponseAllow);
    NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
    NSString * contentRange = [[httpResponse allHeaderFields] objectForKey:@"Content-Range"];
    NSString * fileLength = [[contentRange componentsSeparatedByString:@"/"] lastObject];
    self.fileLength = fileLength.integerValue > 0 ? fileLength.integerValue : response.expectedContentLength;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(requestTaskDidReceiveResponse)])
    {
        [self.delegate requestTaskDidReceiveResponse];
    }
}

//服务器返回数据 可能会调用多次
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    if (self.cancel) return;
    [[XBAVFileHandle shared] writeTempFileData:data forTask:self];
    self.cacheLength += data.length;
    if (self.delegate && [self.delegate respondsToSelector:@selector(requestTaskDidUpdateCache)])
    {
        [self.delegate requestTaskDidUpdateCache];
    }
    
    WEAKSELF
    if (self.bl_progress)
    {
        self.bl_progress(weakSelf);
    }
}

//请求完成会调用该方法，请求失败则error有值
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (self.cancel)
    {
        NSLog(@"手动取消_cancel");
        return;
    }
    if (error)
    {
        if (error.code == 999) //手动取消
        {
            NSLog(@"手动取消_999");
        }
        else
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(requestTaskDidFailWithError:)])
            {
                [self.delegate requestTaskDidFailWithError:error];
            }
        }
    }
    else
    {
        //可以缓存则保存文件
        if (self.cache)
        {
            [[XBAVFileHandle shared] saveTempFileWithTask:self];
        }
        else
        {
            [self deleteTempFile];
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(requestTaskDidFinishLoadingWithCache:)])
        {
            [self.delegate requestTaskDidFinishLoadingWithCache:self.cache];
        }
        
        WEAKSELF
        if (self.bl_progress)
        {
            self.bl_progress(weakSelf);
        }
    }
}

@end

