
#import "ZFPlayerView.h"
#import "ZFPlayerControlView.h"
#import "RFTimer.h"
#import "RFKVOWrapper.h"


static CMTime CMTimeFromNSTimeInterval(NSTimeInterval timeInterval) {
    CMTime time = CMTimeMakeWithSeconds(timeInterval, 1000000);
    return time;
}

static NSTimeInterval NSTimeIntervalFromCMTime(CMTime time) {
    return CMTimeGetSeconds(time);
}

@interface ZFPlayerView ()
@property (nonatomic, readonly) AVPlayerLayer *ZFPlayerView_playerLayer;

@property (nonatomic, strong) NSHashTable<id<ZFPlayerDisplayDelegate>> *ZFPlayerView_displayers;

@property (nonatomic) BOOL ZFPlayerView_observingPlaybackTimeChanges;
@property (nullable, strong) id ZFPlayerView_playbackTimeObserver;
@property (nonatomic) BOOL ZFPlayerView_buffering;
@property (nullable, strong) id ZFPlayerView_bufferEmptyObserver;
@property (nullable, strong) id ZFPlayerView_loadRangeObserver;

@property (nonatomic, strong) RFTimer *debugTimer;
@end

@implementation ZFPlayerView
RFInitializingRootForUIView

- (void)onInit {
    _playbackInfoUpdateInterval = 0.5;
    @weakify(self);
    self.debugTimer = [RFTimer scheduledTimerWithTimeInterval:3 repeats:YES fireBlock:^(RFTimer *timer, NSUInteger repeatCount) {
        @strongify(self);
        douts(@"------")
        dout_bool(self.isPlaying)
        dout_bool(self.paused)
        dout_bool(self.ZFPlayerView_buffering)
        dout_int(self.playerItem.status)
        dout_bool(self.playerItem.playbackBufferEmpty)
        dout_bool(self.playerItem.playbackBufferFull)
        dout_bool(self.playerItem.isPlaybackLikelyToKeepUp)
    }];
}

- (void)afterInit {
    // Nothing
}

+ (instancetype)alloc {
    ZFPlayerView *pv = [super alloc];
    dout(@"Creat %p", pv);
    return pv;
}

- (void)awakeFromNib {
    [super awakeFromNib];

    if (!self.controlView) {
        ZFPlayerControlView *cv = [ZFPlayerControlView loadWithNibName:nil];
        cv.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        cv.frame = self.bounds;
        [self addSubview:cv];
        self.controlView = cv;
    }
}

- (void)dealloc {
    dout(@"%@释放了", self.class);

    self.playerItem = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.debugTimer invalidate];
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
        [self RFRemoveObserverWithIdentifier:self.ZFPlayerView_bufferEmptyObserver];

        self.ZFPlayerView_buffering = NO;
        self.currentTime = 0;
        self.duration = 0;
    }
    _playerItem = playerItem;
    if (playerItem) {
        [nc addObserver:self selector:@selector(ZFPlayerView_handelApplicationWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
        [nc addObserver:self selector:@selector(ZFPlayerView_handelPlayerItemDidPlayToEndTimeNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
        [nc addObserver:self selector:@selector(ZFPlayerView_handelPlaybackStalledNotification:) name:AVPlayerItemPlaybackStalledNotification object:playerItem];
        @weakify(self);
        self.ZFPlayerView_bufferEmptyObserver = [playerItem RFAddObserver:self forKeyPath:@keypath(playerItem, playbackBufferEmpty) options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew queue:[NSOperationQueue mainQueue] block:^(id observer, NSDictionary *change) {
            @strongify(self);
            if (self.playerItem.playbackBufferEmpty) {
                self.ZFPlayerView_buffering = YES;
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
    self.playerItem  = [AVPlayerItem playerItemWithURL:videoURL];
}

- (void)play {
    if (!self.playerItem) {
        dout_warning(@"Cannot play, no playerItem");
        return;
    }

    if (CMTIME_IS_VALID(self.playerItem.duration)
        && CMTimeGetSeconds(self.playerItem.currentTime) == CMTimeGetSeconds(self.playerItem.duration)
        && self.AVPlayer.status == AVPlayerItemStatusReadyToPlay) {
        // 如果播放到末尾，再 play 重头开始
        [self seekToTime:0 completion:nil];
        self.currentTime = 0;
        [self ZFPlayerView_noticePlaybackInfoUpdate];
    }
    else {
        [self.AVPlayer play];
    }
}

- (void)setPaused:(BOOL)paused {
    if (!self.playerItem) {
        paused = NO;
    }
    _paused = paused;

    if (paused) {
        [self.AVPlayer pause];
    }
    else {
        [self play];
    }
    [self ZFPlayerView_noticePauseChanged:paused];
}

- (void)seekToTime:(NSTimeInterval)time completion:(void (^)(BOOL))completion {
    BOOL shouldPausePlaybackObserving = self.ZFPlayerView_observingPlaybackTimeChanges;
    if (shouldPausePlaybackObserving) {
        self.ZFPlayerView_observingPlaybackTimeChanges = NO;
    }
    CMTime tolerance = CMTimeFromNSTimeInterval(0.3);
    [self.AVPlayer seekToTime:CMTimeFromNSTimeInterval(time) toleranceBefore:tolerance toleranceAfter:tolerance completionHandler:^(BOOL finished) {
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
    dispatch_async_on_main(^{
        [self ZFPlayerView_noticePlayToEnd];
        [self ZFPlayerView_noticePauseChanged:YES];
    });
}

- (BOOL)isPlaying {
    return self.AVPlayer.rate != 0;
}

+ (NSSet *)keyPathsForValuesAffectingPlaying {
    return [NSSet setWithObject:@keypathClassInstance(ZFPlayerView, AVPlayer.rate)];
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

- (void)ZFPlayerView_updatePlaybackInfo {
    self.currentTime = NSTimeIntervalFromCMTime(self.playerItem.currentTime);
    if (CMTIME_IS_INDEFINITE(self.playerItem.duration)) {
        self.duration = 0;
    }
    else {
        self.duration = NSTimeIntervalFromCMTime(self.playerItem.duration);
    }
    [self ZFPlayerView_noticePlaybackInfoUpdate];
}

#pragma mark - 缓冲控制

+ (NSSet *)keyPathsForValuesAffectingZFPlayerView_buffering {
    return [NSSet setWithObjects:
            @keypathClassInstance(ZFPlayerView, AVPlayer.status),
            @keypathClassInstance(ZFPlayerView, playerItem.playbackBufferEmpty),
            @keypathClassInstance(ZFPlayerView, playerItem, playbackLikelyToKeepUp),
            nil];
}

- (void)ZFPlayerView_handelPlaybackStalledNotification:(NSNotification *)notice {
    doutwork()
    dispatch_async_on_main(^{
        self.ZFPlayerView_buffering = YES;
    });
}

- (void)setZFPlayerView_buffering:(BOOL)ZFPlayerView_buffering {
    if (_ZFPlayerView_buffering == ZFPlayerView_buffering) return;
    if (_ZFPlayerView_buffering) {
        [self ZFPlayerView_noticeBufferingEnd];
        [self.playerItem RFRemoveObserverWithIdentifier:self.ZFPlayerView_loadRangeObserver];
        self.ZFPlayerView_loadRangeObserver = nil;
        if (!self.paused) {
            [self.AVPlayer play];
        }
    }
    _ZFPlayerView_buffering = ZFPlayerView_buffering;
    if (ZFPlayerView_buffering) {
        NSAssert(self.playerItem, @"Set needs buffering but no playerItem");

        dout_debug(@"Pause to buffer");
        [self.AVPlayer pause];

        @weakify(self);
        self.ZFPlayerView_loadRangeObserver = [self.playerItem RFAddObserver:self forKeyPath:@keypath(self.playerItem, loadedTimeRanges) options:NSKeyValueObservingOptionNew queue:[NSOperationQueue mainQueue] block:^(id observer, NSDictionary *change) {
            @strongify(self);
            // 缓冲够 3s 认为可以继续播放了
            NSTimeInterval loadedRange = self.ZFPlayerView_maxLoadRang;
            if (loadedRange > self.currentTime + 3
                || loadedRange == self.duration) {
                dout_debug(@"Got enough buffer");
                self.ZFPlayerView_buffering = NO;
            }
        }];

        [self ZFPlayerView_noticeBufferingBegin];
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

- (void)setControlView:(ZFPlayerControlView *)controlView {
    if (_controlView != controlView) {
        if (_controlView) {
            [self removeDisplayer:_controlView];
            if (_controlView.player == self) {
                _controlView.player = nil;
            }
        }
        _controlView = controlView;
        if (controlView) {
            [self addDisplayer:controlView];
            controlView.player = self;
        }
    }
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
ZFPlayerDisplayerNoticeMethod2(ZFPlayerView_noticePauseChanged, didChangePauseState, BOOL)
ZFPlayerDisplayerNoticeMethod(ZFPlayerView_noticeBufferingBegin, ZFPlayerWillBeginBuffering);
ZFPlayerDisplayerNoticeMethod(ZFPlayerView_noticeBufferingEnd, ZFPlayerDidEndBuffering);
ZFPlayerDisplayerNoticeMethod(ZFPlayerView_noticePlaybackInfoUpdate, ZFPlayerDidUpdatePlaybackInfo);
ZFPlayerDisplayerNoticeMethod(ZFPlayerView_noticePlayToEnd, ZFPlayerDidPlayToEnd);

@end

