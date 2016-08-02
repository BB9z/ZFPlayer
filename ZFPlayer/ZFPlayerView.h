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
@import AVFoundation;

typedef void(^ZFPlayerGoBackBlock)(void);

@protocol ZFPlayerDisplayDelegate;
@class ZFPlayerControlView;

/**
 对 AVPlayer，AVPlayerLayer 做封装，只提供好播放功能本身。
 
 控制 UI 交给 ZFPlayerControlView 去做，布局应该交给所属的 UIViewController
 */
@interface ZFPlayerView : UIView <
    RFInitializing
>

///
@property (nonatomic, nullable, strong) AVPlayerItem *playerItem;

/// 默认控制层，从 nib 里载入若不设置会自动创建一个
@property (nonatomic, nullable, weak) IBOutlet ZFPlayerControlView *controlView;

- (void)addDisplayer:(nullable id<ZFPlayerDisplayDelegate>)displayer;
- (void)removeDisplayer:(nullable id<ZFPlayerDisplayDelegate>)displayer;

#pragma mark - config

/** 视频URL */
@property (nonatomic, nullable, copy) NSURL *videoURL;

#pragma mark - metho

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

- (void)seekToTime:(NSTimeInterval)time completion:(void (^__nullable)(BOOL finished))completion;

#pragma mark - 状态

typedef NS_ENUM(NSInteger, ZFPlayerState) {
    ZFPlayerStateBuffering,  //缓冲中
    ZFPlayerStatePlaying,    //播放中
    ZFPlayerStateStopped,    //停止播放
    ZFPlayerStatePause       //暂停播放
};
@property (nonatomic, assign) ZFPlayerState status;

/// 播放完了
@property (nonatomic) BOOL playDidEnd;

/// 是否被用户暂停
@property (nonatomic) BOOL isPauseByUser;

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
