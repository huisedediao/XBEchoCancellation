//
//  NSString+XBLoader.h
//  XBMediaPlayer
//
//  Created by xxb on 2017/8/9.
//  Copyright © 2017年 xxb. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (XBLoader)
/**
 *  临时文件夹路径
 */
+ (NSString *)tempFolderPath;

/**
 *  缓存文件夹路径
 */
+ (NSString *)saveFolderPath;
@end
