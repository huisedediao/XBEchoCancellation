//
//  NSString+XBLoader.m
//  XBMediaPlayer
//
//  Created by xxb on 2017/8/9.
//  Copyright © 2017年 xxb. All rights reserved.
//

#import "NSString+XBLoader.h"

@implementation NSString (XBLoader)
+ (NSString *)tempFolderPath
{
    return [[NSHomeDirectory() stringByAppendingPathComponent:@"tmp"] stringByAppendingPathComponent:@"XBMediaTemps"];
}

+ (NSString *)saveFolderPath
{
    return [[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"XBMediaCaches"];
}
@end
