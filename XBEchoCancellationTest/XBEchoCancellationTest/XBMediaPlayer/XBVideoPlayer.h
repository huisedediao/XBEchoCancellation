//
//  XBVideoPlayer.h
//  XBAVPlayer
//
//  Created by xxb on 2017/6/23.
//  Copyright © 2017年 xxb. All rights reserved.
//

/*
 如果app不支持旋转，想要旋转，必须在app里实现这个方法
 2.appDelegate实现了下面这个方法：
 
 -(UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
 
 return UIInterfaceOrientationMaskAll;
 }
 
 支持的视频编码格式很有限：H.264、MPEG-4，扩展名（压缩格式）：.mp4、.mov、.m4v、.m2v、.3gp、.3g2
 
 */

#import "XBAVPlayer.h"

@interface XBVideoPlayer : XBAVPlayer

@property (nonatomic,copy) WaitViewBlock bl_waitView; //等待的view的block

@property (nonatomic,copy) LayoutBlock_vertical bl_layout_vertical; //屏幕竖直状态的布局

@property (nonatomic,copy) LayoutBlock_horizontal bl_layout_horizontal; //屏幕水平状态的布局

@property (nonatomic,copy) VideoPlayerBuildUIBlock bl_buildUI; //视频播放器创建UI的block，只会执行一次（用这个block，避免创建的图层被player的palyerLayer遮挡）


///子类继承
- (void)videoPlayerBuildUI;

@end
