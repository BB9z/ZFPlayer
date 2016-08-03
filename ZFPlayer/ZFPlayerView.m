//
//  ZFPlayerView.m
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
@property (nonatomic, strong) AVPlayerLayer *ZFPlayerView_playerLayer;

@property (nonatomic, strong) NSHashTable<id<ZFPlayerDisplayDelegate>> *ZFPlayerView_displayers;

@property (nonatomic) BOOL ZFPlayerView_observingPlaybackTimeChanges;
@property (nullable, strong) id ZFPlayerView_playbackTimeObserver;

@property (nonatomic, strong) RFTimer *debugTimer;
@end

@implementation ZFPlayerView
RFInitializingRootForUIView

- (void)onInit {
    _playbackInfoUpdateInterval = 0.5;
    @weakify(self);
    self.debugTimer = [RFTimer scheduledTimerWithTimeInterval:1 repeats:YES fireBlock:^(RFTimer *timer, NSUInteger repeatCount) {
        @strongify(self);
        dout_int(self->_AVPlayer.status)
        dout_int(self->_AVPlayer.currentItem.status)
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
//        [_playerItem removeObserver:self forKeyPath:@"status"];
//        [_playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
//        [_playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        self.currentTime = 0;
        self.duration = 0;
    }
    _playerItem = playerItem;
    if (playerItem) {
        [nc addObserver:self selector:@selector(ZFPlayerView_handelApplicationWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
        [nc addObserver:self selector:@selector(ZFPlayerView_handelPlayerItemDidPlayToEndTimeNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];

//        [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
//        // 缓冲区空了，需要等待数据
//        [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
//        // 缓冲区有足够数据可以播放了
//        [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];

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

        [self.AVPlayer replaceCurrentItemWithPlayerItem:playerItem];
        if (self.disableAutoPlayWhenSetPlayItem) {
            self.paused = YES;
        }
        else {
            [self.AVPlayer play];
        }
    }
    [self ZFPlayerView_noticePlayerItemChanged:playerItem];
}

- (void)setVideoURL:(NSURL *)videoURL {
    if (_videoURL == videoURL) return;
    _videoURL = videoURL;
    self.playerItem  = [AVPlayerItem playerItemWithURL:videoURL];
}

- (void)play {
    [self.AVPlayer play];
}

- (void)setPaused:(BOOL)paused {
    if (paused) {
        if (self.playerItem) {
            [self.AVPlayer pause];
            _paused = YES;
        }
    }
    else {
        _paused = NO;
        if (self.playerItem) {
            [self.AVPlayer play];
        }
    }
}

- (void)seekToTime:(NSTimeInterval)time completion:(void (^)(BOOL))completion {
    // TODO: 合适的地方调用 cancelPendingSeeks
    BOOL shouldPausePlaybackObserving = self.ZFPlayerView_observingPlaybackTimeChanges;
    if (shouldPausePlaybackObserving) {
        self.ZFPlayerView_observingPlaybackTimeChanges = NO;
    }
    CMTime tolerance = CMTimeFromNSTimeInterval(0.3);
    [self.AVPlayer seekToTime:CMTimeFromNSTimeInterval(time) toleranceBefore:tolerance toleranceAfter:tolerance completionHandler:^(BOOL finished) {
        if (!self.paused
            && !self.playing) {
            // 没有明确暂停，继续播放
            [self play];
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
    self.playerItem = nil;
}

#pragma mark 事件

- (void)ZFPlayerView_handelApplicationWillResignActiveNotification:(NSNotification *)notice {
    self.paused = YES;
}

- (void)ZFPlayerView_handelPlayerItemDidPlayToEndTimeNotification:(NSNotification *)notice {
    dispatch_async_on_main(^{
        [self ZFPlayerView_noticePlayToEnd];
    });
}

/// 缓冲较差时候回调这里
- (void)bufferingSomeSecond {
    // playbackBufferEmpty会反复进入，因此在bufferingOneSecond延时播放执行完之前再调用bufferingSomeSecond都忽略
    __block BOOL isBuffering = NO;
    if (isBuffering) return;
    isBuffering = YES;

    // 需要先暂停一小会之后再播放，否则网络状况不好的时候时间在走，声音播放不出来
    [self.AVPlayer pause];

    @weakify(self);
    dispatch_after_seconds(1, ^{
        @strongify(self);

        // 如果此时用户已经暂停了，则不再需要开启播放了
        if (self.paused) {
            isBuffering = NO;
            return;
        }

        [self.AVPlayer play];
        // 如果执行了play还是没有播放则说明还没有缓存好，则再次缓存一段时间
        isBuffering = NO;
        if (!self.playerItem.isPlaybackLikelyToKeepUp) {
            [self bufferingSomeSecond];
        }
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
            dout_float(NSTimeIntervalFromCMTime(time))
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


/*
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (object == self.playerItem) {
        if (ZFPlayerKeyIsEqual(keyPath, status)) {
            if (self.player.status == AVPlayerStatusReadyToPlay) {

                self.state = ZFPlayerStatePlaying;

                // 加载完成后，再添加平移手势
                // 添加平移手势，用来控制音量、亮度、快进快退
                UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panDirection:)];
                pan.delegate                = self;
                [self addGestureRecognizer:pan];

            }
            else if (self.player.status == AVPlayerStatusFailed){
//                [self.activity startAnimating];
            }

        }
        else if (ZFPlayerKeyIsEqual(keyPath, playbackBufferEmpty)) {
            // 当缓冲是空的时候
            if (self.playerItem.playbackBufferEmpty) {
                //NSLog(@"playbackBufferEmpty");
                self.state = ZFPlayerStateBuffering;
                [self bufferingSomeSecond];
            }
        }
        else if (ZFPlayerKeyIsEqual(keyPath, playbackLikelyToKeepUp)) {
            // 当缓冲好的时候
            if (self.playerItem.playbackLikelyToKeepUp){
                //NSLog(@"playbackLikelyToKeepUp");
                self.state = ZFPlayerStatePlaying;
            }

        }
    }
}
*/

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

#pragma mark 进度条

- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[self.AVPlayer currentItem] loadedTimeRanges];
    CMTimeRange timeRange     = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds        = CMTimeGetSeconds(timeRange.start);
    float durationSeconds     = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result     = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
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

