//
//  XBAVFileHandle.m
//  XBMediaPlayer
//
//  Created by xxb on 2017/8/9.
//  Copyright © 2017年 xxb. All rights reserved.
//

#import "XBAVFileHandle.h"
#import "XBDataTaskManager.h"
#import "XBRequestTask.h"

@implementation XBAVFileHandle

#pragma mark - 生命周期
+ (instancetype)shared
{
    return [self new];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static XBAVFileHandle *handle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        handle = [super allocWithZone:zone];
    });
    return handle;
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

#pragma mark - 实例方法
/**
 *  创建临时文件
 */
- (BOOL)createTempFileForTask:(XBRequestTask *)task
{
    NSFileManager * manager = [NSFileManager defaultManager];
    NSString *path = [self pathAppendByHomeDirectory:self.dicM_tempFilePath[[task.requestURL originalSchemeURL]]];
    if (path)
    {
        if ([manager fileExistsAtPath:path] == NO)
        {
            return [manager createFileAtPath:path contents:nil attributes:nil];
        }
        else
        {
            return YES;
        }
    }
    else
    {
        path = [self getTempFilePathWithTask:task];
        while ([manager fileExistsAtPath:path])
        {
            static int count = 0;
            path = [path stringByAppendingString:[NSString stringWithFormat:@"%zd",count]];
            count ++;
        }
        self.dicM_tempFilePath[[task.requestURL originalSchemeURL]] = [self pathWithoutHomeDirectory:path];
        [NSKeyedArchiver archiveRootObject:self.dicM_tempFilePath toFile:tempFilePathDicSavePath];
        return [manager createFileAtPath:path contents:nil attributes:nil];
    }
}

/**
 *  往临时文件写入数据
 */
- (void)writeTempFileData:(NSData *)data forTask:(XBRequestTask *)task
{
    NSString *path = [self pathAppendByHomeDirectory:self.dicM_tempFilePath[[task.requestURL originalSchemeURL]]];
    NSFileHandle * handle = [NSFileHandle fileHandleForWritingAtPath:path];
    [handle seekToEndOfFile];
    [handle writeData:data];
}

/**
 *  读取临时文件数据
 */
- (NSData *)readTempFileDataWithOffset:(NSUInteger)offset length:(NSUInteger)length forTask:(XBRequestTask *)task
{
    NSString *path = [self pathAppendByHomeDirectory:self.dicM_tempFilePath[[task.requestURL originalSchemeURL]]];
    NSFileHandle * handle = [NSFileHandle fileHandleForReadingAtPath:path];
    [handle seekToFileOffset:offset];
    NSData *data = [handle readDataOfLength:length];
    return data;
}

/**
 *  保存临时文件到缓存文件夹
 */
- (void)saveTempFileWithTask:(XBRequestTask *)task
{
    NSString *fileSavePath = [self getFileSavePathWithTask:task];
    BOOL success = [[NSFileManager defaultManager] copyItemAtPath:[self pathAppendByHomeDirectory:self.dicM_tempFilePath[[task.requestURL originalSchemeURL]]] toPath:fileSavePath error:nil];
    self.dicM_fileSavePath[[task.requestURL originalSchemeURL]] = [self pathWithoutHomeDirectory:fileSavePath];
    [NSKeyedArchiver archiveRootObject:self.dicM_fileSavePath toFile:fileSavePathDicSavePath];
    NSLog(@"cache file : %@", success ? @"success" : @"fail");
}

/**
 *  是否存在缓存文件 存在：返回文件路径 不存在：返回nil
 */
- (NSString *)fileExistsWithURL:(NSURL *)url
{
    NSString *filePath = [self pathAppendByHomeDirectory:self.dicM_fileSavePath[[url originalSchemeURL]]];
    if (filePath)
    {
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
        {
            return filePath;
        }
        else
        {
            self.dicM_fileSavePath[[url originalSchemeURL]] = nil;
            return nil;
        }
    }
    else
    {
        return nil;
    }
}

/**
 *  清空缓存文件
 */
- (BOOL)clearCache
{
    NSFileManager * manager = [NSFileManager defaultManager];
    self.dicM_tempFilePath = nil;
    return [manager removeItemAtPath:[NSString tempFolderPath] error:nil];
}

/**
 *  删除临时文件
 */
- (void)deleteTempFileForTask:(XBRequestTask *)task
{
    NSFileManager * manager = [NSFileManager defaultManager];
    NSString *path = [self pathAppendByHomeDirectory:self.dicM_tempFilePath[[task.requestURL originalSchemeURL]]];
    if (path)
    {
        if ([manager fileExistsAtPath:path])
        {
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }
        else
        {
            self.dicM_tempFilePath[[task.requestURL originalSchemeURL]] = nil;
        }
    }
    
    [self resetInfoForTask:task];
}

/**
 *  删除某个任务对应的文件（下载好的文件）
 */
- (BOOL)deleteFileForTask:(XBRequestTask *)task
{
    [self resetInfoForTask:task];
    
    NSString * filePath = [self pathAppendByHomeDirectory:self.dicM_fileSavePath[[task.requestURL originalSchemeURL]]];
    self.dicM_fileSavePath[[task.requestURL originalSchemeURL]] = nil;
    NSFileManager * manager = [NSFileManager defaultManager];
    return [manager removeItemAtPath:filePath error:nil];
}

//找到对应的任务，把下载信息还原
- (void)resetInfoForTask:(XBRequestTask *)task
{
    for (XBRequestTask *tempTask in [XBDataTaskManager shared].arrM_taskList)
    {
        if ([tempTask.requestURL.absoluteString isEqualToString:task.requestURL.absoluteString])
        {
            tempTask.cacheLength = 0;
            break;
        }
    }
}

#pragma mark - 其他方法
- (NSString *)getTempFilePathWithTask:(XBRequestTask *)task
{
    NSFileManager * manager = [NSFileManager defaultManager];
    NSString * tempFolderPath = [NSString tempFolderPath];
    if (![manager fileExistsAtPath:tempFolderPath])
    {
        [manager createDirectoryAtPath:tempFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString * tempFilePath = [NSString stringWithFormat:@"%@/%@", tempFolderPath, [self getFileNameWithTask:task]];
    return tempFilePath;
}
- (NSString *)getFileNameWithTask:(XBRequestTask *)task
{
    return task.str_name ? task.str_name : task.requestURL.absoluteString.lastPathComponent;
}
- (NSString *)getFileSavePathWithTask:(XBRequestTask *)task
{
    NSFileManager * manager = [NSFileManager defaultManager];
    NSString * cacheFolderPath = [NSString saveFolderPath];
    if (![manager fileExistsAtPath:cacheFolderPath])
    {
        [manager createDirectoryAtPath:cacheFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString * cacheFilePath = [NSString stringWithFormat:@"%@/%@", cacheFolderPath, [self getFileNameWithTask:task]];
    return cacheFilePath;
}
- (NSString *)pathWithoutHomeDirectory:(NSString *)fullPath
{
    NSString *homePath = NSHomeDirectory();
    NSRange range = [fullPath rangeOfString:homePath];
    return [fullPath substringFromIndex:range.location+range.length];
}
- (NSString *)pathAppendByHomeDirectory:(NSString *)subPath
{
    if (subPath)
    {
        return [NSHomeDirectory() stringByAppendingString:subPath];
    }
    else
    {
        return subPath;
    }
}


#pragma mark - 懒加载
- (NSMutableDictionary *)dicM_tempFilePath
{
    if (_dicM_tempFilePath == nil)
    {
        if ([[NSFileManager defaultManager] fileExistsAtPath:tempFilePathDicSavePath])
        {
            _dicM_tempFilePath = [NSKeyedUnarchiver unarchiveObjectWithFile:tempFilePathDicSavePath];
        }
        else
        {
            _dicM_tempFilePath = [NSMutableDictionary new];
        }
    }
    return _dicM_tempFilePath;
}
- (NSMutableDictionary *)dicM_fileSavePath
{
    if (_dicM_fileSavePath == nil)
    {
        if ([[NSFileManager defaultManager] fileExistsAtPath:fileSavePathDicSavePath])
        {
            _dicM_fileSavePath = [NSKeyedUnarchiver unarchiveObjectWithFile:fileSavePathDicSavePath];
        }
        else
        {
            _dicM_fileSavePath = [NSMutableDictionary new];
        }
    }
    return _dicM_fileSavePath;
}
@end
