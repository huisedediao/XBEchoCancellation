//
//  XBDataTaskManager.h
//  XBMediaPlayer
//
//  Created by xxb on 2017/8/9.
//  Copyright © 2017年 xxb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XBRequestTask.h"

@interface XBDataTaskManager : NSObject
@property (nonatomic,strong) NSMutableArray *arrM_taskList;
///从url添加任务，参数1：url， 参数2：是否开始任务
- (void)addDataTaskWithUrl:(NSURL *)url start:(BOOL)start;
- (void)addDataTask:(XBRequestTask *)task;
- (void)removeDataTask:(XBRequestTask *)task;
- (void)save;
- (void)stopAllTask;
+ (instancetype)shared;
@end
