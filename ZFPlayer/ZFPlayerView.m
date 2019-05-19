
#import "ZFPlayerView.h"
#import <RFAlpha/RFKVOWrapper.h>
#if __has_include("RFTimer.h")
#import <RFAlpha/RFTimer.h>
#endif

#ifndef ZFPlayerDebug
#define ZFPlayerDebug 0
#endif

static CMTime CMTimeFromNSTimeInterval(NSTimeInterval timeInterval) {
    CMTime time = CMTimeMakeWithSeconds(timeInterval, 1000000);
    return time;
}

static NSTimeInterval NSTimeIntervalFromCMTime(CMTime time) {
    return CMTimeGetSeconds(time);
}

@interface ZFPlayerView ()
@property (nonatomic, readonly) AVPlayerLayer *ZFPlayerView_playerLayer;

@property (nonatomic) NSHashTable<id<ZFPlayerDisplayDelegate>> *ZFPlayerView_displayers;

@property (nonatomic) BOOL ZFPlayerView_observingPlaybackTimeChanges;
@property (nullable) id ZFPlayerView_playbackTimeObserver;
@property (nullable) id ZFPlayerView_bufferEmptyObserver;
@property (nullable) id ZFPlayerView_loadRangeObserver;
@property (nonatomic) BOOL ZFPlayerView_currentPauseDueToBuffering;
#if ZFPlayerDebug
@property RFTimer *debugTimer;
#endif
@end

@implementation ZFPlayerView
RFInitializingRootForUIView

- (void)onInit {
    _playbackInfoUpdateInterval = 0.5;
    _seekingTime = -1;
#if ZFPlayerDebug
    @weakify(self);
    self.debugTimer = [RFTimer scheduledTimerWithTimeInterval:3 repeats:YES fireBlock:^(RFTimer *timer, NSUInteger repeatCount) {
        @strongify(self);
        if (self.window) {
            dout(@"%@", self.debugDescription);
        }
    }];
#endif
}

- (void)afterInit {
    // Nothing
}

- (void)dealloc {
    self.playerItem = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#if ZFPlayerDebug
    [self.debugTimer invalidate];
#endif
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];

    if (newWindow) {
        self.ZFPlayerView_observingPlaybackTimeChanges = YES;
    }
    else {
        // 从 view hierarchy 移除，需要暂停
        self.paused = YES;
        self.ZFPlayerView_observingPlaybackTimeChanges = NO;
    }
}

- (NSString *)debugDescription {
    NSString *playStatus = @"";
    NSString *playSource = nil;
    if (self.videoURL) {
        playSource = [NSString stringWithFormat:@"videoURL = %@", self.videoURL];
    }
    else if (self.playerItem) {
        playSource = [NSString stringWithFormat:@"playerItem = %@", self.playerItem];
    }
    if (playSource) {
        playStatus = [playStatus stringByAppendingFormat:@" \
rate: %.1f, paused: %@, status: %@, \
progress: %.1f/%.1f, loadRang: %.1f \
buffering: %@, empty?: %@, full?:%@, likelyToKeepUp?: %@",
                      self.AVPlayer.rate, @(self.paused), @(self.playerItem.status),
                      self.currentTime, self.duration, self.ZFPlayerView_maxLoadRang,
                      @(self.buffering), @(self.playerItem.playbackBufferEmpty), @(self.playerItem.playbackBufferFull), @(self.playerItem.isPlaybackLikelyToKeepUp)
                      ];
    }
    return [NSString stringWithFormat:@"<%@: %p, %@%@>", self.class, (void *)self,
            playSource?: @"no play item", playStatus];
}

#pragma mark - 播放核心属性

@synthesize AVPlayer = _AVPlayer;

- (AVPlayer *)AVPlayer {
    if (!_AVPlayer) {
        AVPlayer *ap = [AVPlayer playerWithPlayerItem:self.playerItem];
        AVPlayerLayer *al = [AVPlayerLayer playerLayerWithPlayer:ap];
        [self.layer insertSublayer:al atIndex:0];
        _ZFPlayerView_playerLayer = al;
        _AVPlayer = ap;
    }
    return _AVPlayer;
}

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    [super layoutSublayersOfLayer:layer];
    if (layer == self.layer) {
        self.ZFPlayerView_playerLayer.frame = self.bounds;
    }
}

#pragma mark - 播放器控制

- (void)setPlayerItem:(AVPlayerItem *)playerItem {
    if (_playerItem == playerItem) return;

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    if (_playerItem) {
        [nc removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
        [nc removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
        [nc removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:_playerItem];
        [nc removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:_playerItem];
        [self RFRemoveObserverWithIdentifier:self.ZFPlayerView_bufferEmptyObserver];

        self.buffering = NO;
        self.currentTime = 0;
        self.playReachEnd = NO;
        self.duration = 0;
        // 强制重设，否则如果之前出错不能正常播放
        [self.AVPlayer replaceCurrentItemWithPlayerItem:nil];
    }
    _playerItem = playerItem;
    if (playerItem) {
        [nc addObserver:self selector:@selector(ZFPlayerView_handelApplicationWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
        [nc addObserver:self selector:@selector(ZFPlayerView_handelPlayerItemDidPlayToEndTimeNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
        [nc addObserver:self selector:@selector(ZFPlayerView_handelPlaybackStalledNotification:) name:AVPlayerItemPlaybackStalledNotification object:playerItem];
        [nc addObserver:self selector:@selector(ZFPlayerView_handelPlayerItemFailedToPlayToEndTimeNotification:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:playerItem];
        self.ZFPlayerView_bufferEmptyObserver = [playerItem RFAddObserver:self forKeyPath:@keypath(playerItem, isPlaybackBufferEmpty) options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew queue:[NSOperationQueue mainQueue] block:^(ZFPlayerView *observer, NSDictionary *change) {
            if (observer.playerItem.playbackBufferEmpty) {
                observer.buffering = YES;
            }
        }];
        [playerItem RFAddObserver:self forKeyPath:@keypath(playerItem, status) options:NSKeyValueObservingOptionNew queue:nil block:^(ZFPlayerView *observer, NSDictionary *change) {
            if (observer.playerItem.status == AVPlayerStatusFailed) {
                [observer ZFPlayerView_handlePlayError:observer.playerItem.error];
            }
        }];

        // 同步 videoURL 属性
        if ([playerItem.asset isKindOfClass:[AVURLAsset class]]) {
            NSURL *assetURL = [(AVURLAsset *)playerItem.asset URL];
            if (![assetURL isEqual:self.videoURL]) {
                _videoURL = assetURL;
            }
        }
        else {
            _videoURL = nil;
        }
        self.paused = self.disableAutoPlayWhenSetPlayItem;
    }
    [self.AVPlayer replaceCurrentItemWithPlayerItem:playerItem];
    [self ZFPlayerView_noticePlayerItemChanged:playerItem];
}

- (void)setVideoURL:(NSURL *)videoURL {
    if (_videoURL == videoURL) return;
    _videoURL = videoURL;
    self.playerItem = [AVPlayerItem playerItemWithURL:videoURL];
}

- (void)play {
    if (!self.playerItem) {
        dout_warning(@"Cannot play, no playerItem");
        return;
    }
    [self.AVPlayer play];
}

- (void)setPaused:(BOOL)paused {
    BOOL shouldNoticeDisplayer = YES;
    if (!self.playerItem) {
        paused = NO;
        shouldNoticeDisplayer = NO;
    }
    if (_paused != paused) {
        _paused = paused;
    }

    if (paused) {
        self.ZFPlayerView_currentPauseDueToBuffering = NO;
        [self.AVPlayer pause];
    }
    else {
        [self play];
    }
    if (shouldNoticeDisplayer) {
        [self ZFPlayerView_noticePauseChanged:paused];
    }
}

- (void)seekToTime:(NSTimeInterval)time completion:(void (^)(BOOL))completion {
    if (!self.playerItem) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    BOOL shouldPausePlaybackObserving = self.ZFPlayerView_observingPlaybackTimeChanges;
    if (shouldPausePlaybackObserving) {
        self.ZFPlayerView_observingPlaybackTimeChanges = NO;
    }
    self.buffering = YES;
    CMTime tolerance = CMTimeFromNSTimeInterval(0.1);
    self.seekingTime = time;
    self.playReachEnd = NO;
    @weakify(self);
    [self.AVPlayer seekToTime:CMTimeFromNSTimeInterval(time) toleranceBefore:tolerance toleranceAfter:tolerance completionHandler:^(BOOL finished) {
        @strongify(self);
        if (finished) {
            self.seekingTime = -1;
        }
        [self ZFPlayerView_tryExitBuffering];
        if (!self.paused
            && !self.playing) {
            // 没有明确暂停，继续播放
            [self.AVPlayer play];
        }
        if (completion) {
            completion(finished);
        }
        if (shouldPausePlaybackObserving) {
            self.ZFPlayerView_observingPlaybackTimeChanges = YES;
        }
    }];
}

- (void)stop {
    [self.AVPlayer pause];  // 为了重置 rate
    self.playerItem = nil;
}

#pragma mark 事件

- (void)ZFPlayerView_handelApplicationWillResignActiveNotification:(NSNotification *)notice {
    self.paused = YES;
}

- (void)ZFPlayerView_handelPlayerItemDidPlayToEndTimeNotification:(NSNotification *)notice {
    self.playReachEnd = YES;
    dispatch_async_on_main(^{
        [self ZFPlayerView_noticePlayToEnd];
        [self ZFPlayerView_noticePauseChanged:YES];
    });
}

- (void)ZFPlayerView_handelPlayerItemFailedToPlayToEndTimeNotification:(NSNotification *)notice {
    NSError *error = notice.userInfo[AVPlayerItemFailedToPlayToEndTimeErrorKey];
    [self ZFPlayerView_handlePlayError:error];
}

- (BOOL)isPlaying {
    if (self.playerItem.playbackBufferEmpty
        && !self.playerItem.playbackLikelyToKeepUp) {
        // 视频刚开始加载时，可能 rate 正常，但没有足够的缓冲
        // 完全缓冲时，有遇到 empty 为 YES 的情况……
        return NO;
    }
    return (self.AVPlayer.rate != 0);
}

+ (NSSet *)keyPathsForValuesAffectingPlaying {
    return [NSSet setWithObject:@keypathClassInstance(ZFPlayerView, AVPlayer.rate)];
}

- (void)ZFPlayerView_handlePlayError:(NSError *)error {
    self.buffering = NO;
    dispatch_async_on_main(^{
        [self ZFPlayerView_noticePlayError:error];
    });
}

#pragma mark - Playback info update

- (void)setZFPlayerView_observingPlaybackTimeChanges:(BOOL)observingPlaybackTimeChanges {
    if (_ZFPlayerView_observingPlaybackTimeChanges == observingPlaybackTimeChanges) return;

    if (_ZFPlayerView_observingPlaybackTimeChanges) {
        if (self.ZFPlayerView_playbackTimeObserver) {
            [self.AVPlayer removeTimeObserver:self.ZFPlayerView_playbackTimeObserver];
        }
    }
    _ZFPlayerView_observingPlaybackTimeChanges = observingPlaybackTimeChanges;
    if (observingPlaybackTimeChanges) {
        @weakify(self);
        NSTimeInterval interval = self.playbackInfoUpdateInterval;
        if (interval <= 0) return;
        self.ZFPlayerView_playbackTimeObserver = [self.AVPlayer addPeriodicTimeObserverForInterval:CMTimeFromNSTimeInterval(interval) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            @strongify(self);
            _dout_float(NSTimeIntervalFromCMTime(time))
            [self ZFPlayerView_updatePlaybackInfo];
        }];
    }
}

- (void)ZFPlayerView_updatePlaybackProprties {
    NSTimeInterval currentTime = NSTimeIntervalFromCMTime(self.playerItem.currentTime);
    self.currentTime = isnan(currentTime)? 0 : currentTime;
    if (CMTIME_IS_INDEFINITE(self.playerItem.duration)) {
        self.duration = 0;
    }
    else {
        NSTimeInterval duration = NSTimeIntervalFromCMTime(self.playerItem.duration);
        self.duration = isnan(duration)? 0 : duration;
    }
#if ZFPlayerDebug
    if (self.duration) {
        BOOL reachEnd = (self.currentTime >= self.duration);
        if (reachEnd != self.playReachEnd) {
            dout_info(@"playReachEnd 状态的维护不是很确定，应该跟时间判断一致");
        }
    }
#endif
}

- (void)ZFPlayerView_updatePlaybackInfo {
    [self ZFPlayerView_updatePlaybackProprties];
    [self ZFPlayerView_noticePlaybackInfoUpdate];
}

#pragma mark - 缓冲控制

+ (NSSet *)keyPathsForValuesAffectingBuffering {
    return [NSSet setWithObjects:
            @keypathClassInstance(ZFPlayerView, AVPlayer.status),
            @keypathClassInstance(ZFPlayerView, playerItem.playbackBufferEmpty),
            @keypathClassInstance(ZFPlayerView, playerItem, playbackLikelyToKeepUp),
            nil];
}

- (void)ZFPlayerView_handelPlaybackStalledNotification:(NSNotification *)notice {
    dispatch_async_on_main(^{
        self.buffering = YES;
    });
}

- (void)setBuffering:(BOOL)buffering {
    if (_buffering == buffering) {
        if (buffering) {
            if (self.ZFPlayerView_currentPauseDueToBuffering
                && !self.paused) {
                // 解决处于缓冲时点播放
                self.paused = YES;
                self.ZFPlayerView_currentPauseDueToBuffering = YES;
            }
        }
        return;
    }
    if (_buffering) {
        [self.playerItem RFRemoveObserverWithIdentifier:self.ZFPlayerView_loadRangeObserver];
        self.ZFPlayerView_loadRangeObserver = nil;
        if (self.ZFPlayerView_currentPauseDueToBuffering) {
            self.ZFPlayerView_currentPauseDueToBuffering = NO;
            self.paused = NO;
        }
    }
    _buffering = buffering;
    if (buffering) {
        NSAssert(self.playerItem, @"Set needs buffering but no playerItem");

        self.paused = YES;
        self.ZFPlayerView_currentPauseDueToBuffering = YES;

        self.ZFPlayerView_loadRangeObserver = [self.playerItem RFAddObserver:self forKeyPath:@keypath(self.playerItem, loadedTimeRanges) options:NSKeyValueObservingOptionNew queue:[NSOperationQueue mainQueue] block:^(ZFPlayerView *observer, NSDictionary *change) {
            [observer ZFPlayerView_tryExitBuffering];
        }];
    }
    [self ZFPlayerView_noticeBufferingChanged:buffering];
}

- (void)ZFPlayerView_tryExitBuffering {
    NSTimeInterval loadedRange = self.ZFPlayerView_maxLoadRang;
    NSTimeInterval duration = NSTimeIntervalFromCMTime(self.playerItem.duration);
    if (duration > 0
        && loadedRange >= duration) {
        // 加载到末尾了，可以结束缓冲
        self.buffering = NO;
    }
    else if (self.playerItem.isPlaybackLikelyToKeepUp) {
        // 系统认为可以了
        self.buffering = NO;
    }
}

/// 当前已缓冲的时间
- (NSTimeInterval)ZFPlayerView_maxLoadRang {
    NSTimeInterval time = 0;
    for (NSValue *rangObject in self.playerItem.loadedTimeRanges) {
        CMTimeRange rang = [rangObject CMTimeRangeValue];
        NSTimeInterval start = NSTimeIntervalFromCMTime(rang.start);
        NSTimeInterval duration = NSTimeIntervalFromCMTime(rang.duration);
        NSTimeInterval rangMax = start + duration;
        if (time < rangMax) {
            time = rangMax;
        }
    }
    return time;
}

#pragma mark - UI 逻辑

- (BOOL)shouldApplyFullscreenLayout {
    // 到底是什么决定视频是否处于全屏？实际并不是设备方向！
    // 想想分屏、不在主屏幕的情形，旋转设备影响的只是容器的尺寸
    CGRect windowFrame = self.window.frame;
    return CGRectGetWidth(windowFrame) > CGRectGetHeight(windowFrame);
}

#pragma mark - Delegtate 通知

- (NSHashTable<id<ZFPlayerDisplayDelegate>> *)ZFPlayerView_displayers {
    if (!_ZFPlayerView_displayers) {
        _ZFPlayerView_displayers = [NSHashTable weakObjectsHashTable];
    }
    return _ZFPlayerView_displayers;
}

- (void)addDisplayer:(id<ZFPlayerDisplayDelegate>)displayer {
    if (displayer) {
        [self.ZFPlayerView_displayers addObject:displayer];
    }
}

- (void)removeDisplayer:(id<ZFPlayerDisplayDelegate>)displayer {
    if (displayer) {
        [self.ZFPlayerView_displayers removeObject:displayer];
    }
}

/**
 通知生成方法
 */
#define ZFPlayerDisplayerNoticeMethod(METHODNAME, PROTOCOL_SELECTOR) \
    - (void)METHODNAME {\
        NSArray *all = [self.ZFPlayerView_displayers allObjects];\
        for (id<ZFPlayerDisplayDelegate> displayer in all) {\
            if ([displayer respondsToSelector:@selector(PROTOCOL_SELECTOR:)]) {\
                [displayer PROTOCOL_SELECTOR:self];\
            }\
        }\
    }

#define ZFPlayerDisplayerNoticeMethod2(METHODNAME, PROTOCOL_SELECTOR, PAR_TYPE) \
    - (void)METHODNAME:(PAR_TYPE)PAR {\
        NSArray *all = [self.ZFPlayerView_displayers allObjects];\
        for (id<ZFPlayerDisplayDelegate> displayer in all) {\
            if ([displayer respondsToSelector:@selector(ZFPlayer:PROTOCOL_SELECTOR:)]) {\
                [displayer ZFPlayer:self PROTOCOL_SELECTOR:PAR];\
            }\
        }\
    }

ZFPlayerDisplayerNoticeMethod2(ZFPlayerView_noticePlayerItemChanged, didChangePlayerItem, AVPlayerItem *)
ZFPlayerDisplayerNoticeMethod2(ZFPlayerView_noticeBufferingChanged, buffering, BOOL)
ZFPlayerDisplayerNoticeMethod2(ZFPlayerView_noticePauseChanged, didChangePauseState, BOOL)
ZFPlayerDisplayerNoticeMethod(ZFPlayerView_noticePlaybackInfoUpdate, ZFPlayerDidUpdatePlaybackInfo);
ZFPlayerDisplayerNoticeMethod(ZFPlayerView_noticePlayToEnd, ZFPlayerDidPlayToEnd);
ZFPlayerDisplayerNoticeMethod2(ZFPlayerView_noticePlayError, didReciveError, NSError *);

@end

