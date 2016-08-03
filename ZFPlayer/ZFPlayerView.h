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

/// 不可能把 AVPlayer 上所有功能都做一层封装，这需要太多的代码。
/// 尽量用 ZFPlayerView 提供好的方法而不是直接调用 AVPlayer 上的
@property (nonatomic, nonnull, readonly) AVPlayer *AVPlayer;

/// 正在播放的视频对象，设置这个属性可以切换视频
@property (nonatomic, nullable, strong) AVPlayerItem *playerItem;

/// 正在播放视频的 URL，可能有正在播放仍为空的情形，设置这个属性可以切换视频
@property (nonatomic, nullable, copy) NSURL *videoURL;

/// 默认控制层，从 nib 里载入若不设置会自动创建一个
@property (nonatomic, nullable, weak) IBOutlet ZFPlayerControlView *controlView;

- (void)addDisplayer:(nullable id<ZFPlayerDisplayDelegate>)displayer;
- (void)removeDisplayer:(nullable id<ZFPlayerDisplayDelegate>)displayer;

#pragma mark - config

/// 默认 0.5s，不大于 0 不刷新
@property (nonatomic) IBInspectable NSTimeInterval playbackInfoUpdateInterval;

#pragma mark - metho

/** 
 *  播放
 */
- (void)play;

/** 
  * 暂停 
 */
- (void)pause;

- (void)seekToTime:(NSTimeInterval)time completion:(void (^__nullable)(BOOL finished))completion;

/// 停止播放并清理状态
- (void)stop;

#pragma mark - 状态

typedef NS_ENUM(NSInteger, ZFPlayerState) {
    ZFPlayerStateBuffering,  //缓冲中
    ZFPlayerStatePlaying,    //播放中
    ZFPlayerStateStopped,    //停止播放
    ZFPlayerStatePause       //暂停播放
};
@property (nonatomic, assign) ZFPlayerState status;

@property (nonatomic, getter=isPlaying) BOOL playing;

/// 当前已播放时间，特殊状态下的定义暂不明确
@property NSTimeInterval currentTime;

/// 当前播放视频的时长，特殊状态下的定义暂不明确
@property NSTimeInterval duration;

/// 播放完了
@property (nonatomic) BOOL playDidEnd;

/// 是否被用户暂停
@property (nonatomic) BOOL isPauseByUser;

@end


@protocol ZFPlayerDisplayDelegate <NSObject>
@optional

- (void)ZFPlayerDidUpdatePlaybackInfo:(nonnull ZFPlayerView *)player;
- (void)ZFPlayer:(nonnull ZFPlayerView *)player didChangePlayerItem:(nullable AVPlayerItem *)playerItem;


@end
