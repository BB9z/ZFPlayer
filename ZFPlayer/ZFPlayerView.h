//
//  ZFPlayerView.h
//
// Copyright (c) 2016年 任子丰 ( http://github.com/renzifeng )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "RFUI.h"
#import <XXNibBridge/XXNibBridge.h>
@import AVFoundation;

typedef void(^ZFPlayerGoBackBlock)(void);

@protocol ZFPlayerDisplayDelegate;
@class ZFPlayerControlView;

/**
 
 */
@interface ZFPlayerView : UIView <
    RFInitializing,
    XXNibBridge
>

///
@property (nonatomic, nullable, strong) AVPlayerItem *playerItem;

/// 默认控制层，从 nib 里载入若不设置会自动创建一个
@property (nonatomic, nullable, weak) IBOutlet ZFPlayerControlView *controlView;

- (void)addDisplayer:(nullable id<ZFPlayerDisplayDelegate>)displayer;
- (void)removeDisplayer:(nullable id<ZFPlayerDisplayDelegate>)displayer;

#pragma mark - UI

/** 快进快退label */
@property (nonatomic, nullable, weak) IBOutlet UILabel *horizontalLabel;
/** 系统菊花 */
@property (nonatomic, nullable, weak) IBOutlet UIActivityIndicatorView *activity;
/** 返回按钮*/
@property (nonatomic, nullable, weak) IBOutlet UIButton *backBtn;
/** 重播按钮 */
@property (nonatomic, nullable, weak) IBOutlet UIButton *repeatBtn;

#pragma mark - config

/** 视频URL */
@property (nonatomic, nullable, copy) NSURL *videoURL;

/** 返回按钮Block */
@property (nonatomic, nullable, copy) ZFPlayerGoBackBlock goBackBlock;

#pragma mark - metho

/**
 *  player添加到cell上
 *
 *  @param cell 添加player的cellImageView
 */
- (void)addPlayerToCellImageView:(nonnull UIImageView *)imageView;

/**
 *  重置player
 */
- (void)resetPlayer;

/** 
 *  播放
 */
- (void)play;

/** 
  * 暂停 
 */
- (void)pause;

#pragma mark - 全屏模式

@property (nonatomic) BOOL fullscreenMode;

- (void)setFullscreenMode:(BOOL)fullscreen animated:(BOOL)animated;

/// 全屏时锁定屏幕方向
@property (nonatomic, getter=isLockOrientationWhenFullscreen) BOOL lockOrientationWhenFullscreen;

/// 设备旋转时自动切换全屏模式，默认 YES
@property (nonatomic) BOOL changeFullscreenModeWhenDeviceOrientationChanging;

@end


@protocol ZFPlayerDisplayDelegate <NSObject>
@optional

- (void)ZFPlayerDidChangedFullscreenMode:(nonnull ZFPlayerView *)player;
- (void)ZFPlayerDidChangedLockOrientationWhenFullscreen:(nonnull ZFPlayerView *)player;

@end
