//
//  NSURL+XBLoader.h
//  XBMediaPlayer
//
//  Created by xxb on 2017/8/9.
//  Copyright © 2017年 xxb. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (XBLoader)
/**
 *  自定义scheme
 */
- (NSURL *)customSchemeURL;

/**
 *  还原scheme
 */
- (NSURL *)originalSchemeURL;
@end
