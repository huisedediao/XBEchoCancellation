//
//  XBDataTaskManager.m
//  XBMediaPlayer
//
//  Created by xxb on 2017/8/9.
//  Copyright © 2017年 xxb. All rights reserved.
//

#import "XBDataTaskManager.h"
#import "NSURL+XBLoader.h"
#import "XBLoaderHeader.h"
#import "XBAVFileHandle.h"

@implementation XBDataTaskManager

+ (instancetype)shared
{
    return [self new];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static XBDataTaskManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [super allocWithZone:zone];
    });
    return manager;
}

- (instancetype)init
{
    if (self == [super init])
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            if ([[NSFileManager defaultManager] fileExistsAtPath:XBMediaFolderPath] == false)
            {
                [[NSFileManager defaultManager] createDirectoryAtPath:XBMediaFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
        });
    }
    return self;
}

- (NSMutableArray *)arrM_taskList
{
    if (_arrM_taskList == nil)
    {
        if ([[NSFileManager defaultManager] fileExistsAtPath:arrM_taskListSavePath])
        {
            _arrM_taskList = [NSKeyedUnarchiver unarchiveObjectWithFile:arrM_taskListSavePath];
        }
        else
        {
            _arrM_taskList = [NSMutableArray new];
        }
    }
    return _arrM_taskList;
}


///从url添加任务，参数1：url， 参数2：是否开始任务
- (void)addDataTaskWithUrl:(NSURL *)url start:(BOOL)start
{
    XBRequestTask *requestTask = [[XBRequestTask alloc] init];
    requestTask.requestURL = [url customSchemeURL];
    requestTask.cache = YES;
    if (start)
    {
        [requestTask start];
    }
    [[XBDataTaskManager shared] addDataTask:requestTask];
}

- (void)addDataTask:(XBRequestTask *)task
{
    if ([self.arrM_taskList containsObject:task] == NO)
    {
        [self.arrM_taskList addObject:task];
        [NSKeyedArchiver archiveRootObject:self.arrM_taskList toFile:arrM_taskListSavePath];
    }
}

- (void)removeDataTask:(XBRequestTask *)task
{
    if ([self.arrM_taskList containsObject:task])
    {
        //找到对应的文件删除
        [[XBAVFileHandle shared] deleteFileForTask:task];
        [[XBAVFileHandle shared] deleteTempFileForTask:task];
        
        [self.arrM_taskList removeObject:task];
        [NSKeyedArchiver archiveRootObject:self.arrM_taskList toFile:arrM_taskListSavePath];
    }
}

- (void)save
{
    [self stopAllTask];
    [NSKeyedArchiver archiveRootObject:self.arrM_taskList toFile:arrM_taskListSavePath];
}

- (void)stopAllTask
{
    for (XBRequestTask *task in self.arrM_taskList)
    {
        [task stop];
    }
}
@end
