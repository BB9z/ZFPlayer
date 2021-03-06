/*!
 ZFPlayerView
 
 Copyright © 2016, 2018-2019 BB9z.
 Copyright © 2016 任子丰 http://github.com/renzifeng
 https://github.com/BB9z/ZFPlayer
 
 The MIT License (MIT)
 http://www.opensource.org/licenses/mit-license.php
 */
#import <AVFoundation/AVFoundation.h>
#import <RFInitializing/RFInitializing.h>
#import <RFKit/RFRuntime.h>

@protocol ZFPlayerDisplayDelegate;

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
@property (nonatomic, nullable) AVPlayerItem *playerItem;

/// 正在播放视频的 URL，可能有正在播放仍为空的情形，设置这个属性可以切换视频
@property (nonatomic, nullable, copy) NSURL *videoURL;

#pragma mark - 播放控制

/// 尝试开始播放
- (void)play;

/// 设置暂停，如果没有视频在播放总是 NO
@property (nonatomic, getter=isPaused) BOOL paused;

/// @bug: 目前暂停时调节进度会退出暂停状态，计划 1.2 修正
- (void)seekToTime:(NSTimeInterval)time completion:(void (^__nullable)(BOOL finished))completion;

/// 正在切换的时间点，不在切换时值 -1
@property NSTimeInterval seekingTime;

/// 停止播放并清理状态
- (void)stop;

#pragma mark - 状态

/// 视频是否正在播放，处于缓冲状态为 NO
@property (readonly, getter=isPlaying) BOOL playing;

/// 当前已播放时间，在调整当前播放时间时，UI 可能需要显示 seekingTime
/// 其他特殊状态下的定义暂不明确
@property NSTimeInterval currentTime;

/// 当前播放视频的时长
/// 视频未加载或正在加载但未获取到时长时为 0
@property NSTimeInterval duration;

/// 视频播放到末尾
@property (getter=isPlayReachEnd) BOOL playReachEnd;

/// 是否处于影响播放的缓冲状态，缓冲但可以正常播放不在此情形中
/// 正常进入该状态时会停止播放，假如用户继续播放，这个状态不会自动退出
@property (nonatomic, readonly, getter=isBuffering) BOOL buffering;

/// 根据当前 view hierarchy 决定是否应处于全屏布局
- (BOOL)shouldApplyFullscreenLayout;

/// 对当前视频截图
/// @note 当前实现支持流视频，但调用时视频会卡顿一下
- (void)takeScreenShot:(nonnull void (^)(UIImage *__nullable))complation;

#pragma mark - 配置

/// 默认设置 videoURL 或 playerItem 就开始自动播放，置为 YES 必须手动调用 play 方法才开始播放
@property IBInspectable BOOL disableAutoPlayWhenSetPlayItem;

/// 默认 0.5s，不大于 0 不刷新
@property IBInspectable NSTimeInterval playbackInfoUpdateInterval;

#pragma mark - 状态监听

// 并不推荐使用 KVO，原生的 KVO 代码 90% 的人都不能完全写对
// 这里的 displayer 是 delegate 模式的增强，你可以设置多个独立的 displayer
// PS: 所有未注明不支持 KVO 的属性均支持 KVO

- (void)addDisplayer:(nullable id<ZFPlayerDisplayDelegate>)displayer;
- (void)removeDisplayer:(nullable id<ZFPlayerDisplayDelegate>)displayer;

@end


@protocol ZFPlayerDisplayDelegate <NSObject>
@optional

/// 视频切换时通知
- (void)ZFPlayer:(nonnull ZFPlayerView *)player didChangePlayerItem:(nullable AVPlayerItem *)playerItem;

/// 播放开始/暂停时通知，因缓冲不足停止播放不会调用
- (void)ZFPlayer:(nonnull ZFPlayerView *)player didChangePauseState:(BOOL)isPaused;

/// buffering 状态变化时调用
- (void)ZFPlayer:(nonnull ZFPlayerView *)player buffering:(BOOL)isBuffering;

/// 视频播放时，会周期性调用通知刷新播放进度
- (void)ZFPlayerDidUpdatePlaybackInfo:(nonnull ZFPlayerView *)player;

/// 视频播放到末尾时通知
- (void)ZFPlayerDidPlayToEnd:(nonnull ZFPlayerView *)player;

/// 播放错误
- (void)ZFPlayer:(nonnull ZFPlayerView *)player didReciveError:(nullable NSError *)error;

/// 即将调节进度时调用
- (void)ZFPlayer:(nonnull ZFPlayerView *)player willBeginSeek:(NSTimeInterval)time;

@end
