//
//  XBAVFileHandle.h
//  XBMediaPlayer
//
//  Created by xxb on 2017/8/9.
//  Copyright © 2017年 xxb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XBRequestTask.h"
#import "NSURL+XBLoader.h"
#import "NSString+XBLoader.h"
#import "XBLoaderHeader.h"


@interface XBAVFileHandle : NSObject

@property (nonatomic,strong) NSMutableDictionary *dicM_tempFilePath;
@property (nonatomic,strong) NSMutableDictionary *dicM_fileSavePath;

+ (instancetype)shared;

/**
 *  创建临时文件
 */
- (BOOL)createTempFileForTask:(XBRequestTask *)task;

/**
 *  往临时文件写入数据
 */
- (void)writeTempFileData:(NSData *)data forTask:(XBRequestTask *)task;

/**
 *  读取临时文件数据
 */
- (NSData *)readTempFileDataWithOffset:(NSUInteger)offset length:(NSUInteger)length forTask:(XBRequestTask *)task;

/**
 *  保存临时文件到缓存文件夹
 */
- (void)saveTempFileWithTask:(XBRequestTask *)task;

/**
 *  是否存在缓存文件 存在：返回文件路径 不存在：返回nil
 */
- (NSString *)fileExistsWithURL:(NSURL *)url;

/**
 *  清空缓存文件
 */
- (BOOL)clearCache;

/**
 *  删除临时文件
 */
- (void)deleteTempFileForTask:(XBRequestTask *)task;

/**
 *  删除某个任务对应的文件（下载好的文件）
 */
- (BOOL)deleteFileForTask:(XBRequestTask *)task;

///把字符串添加到主目录后面
- (NSString *)pathAppendByHomeDirectory:(NSString *)subPath;
@end
