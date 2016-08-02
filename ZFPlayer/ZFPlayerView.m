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

@interface UIDevice (Fake)
- (void)setOrientation:(int)orientation animated:(BOOL)animated;
@end

@interface ZFPlayerView ()
@property (nonatomic, strong) AVPlayerLayer *ZFPlayerView_playerLayer;

@property (nonatomic, strong) NSHashTable<id<ZFPlayerDisplayDelegate>> *displayers;

/// 控制是否监听屏幕旋转事件
@property (nonatomic) BOOL observingOrientationChangeEvent;
@property (nonatomic) BOOL deviceBeginGeneratingOrientationNotificationsChangedByMine;

@property (nonatomic) BOOL ZFPlayerView_observingPlaybackTimeChanges;
@property (nullable, strong) id ZFPlayerView_playbackTimeObserver;
@end

@implementation ZFPlayerView
RFInitializingRootForUIView

- (void)onInit {
    self.changeFullscreenModeWhenDeviceOrientationChanging = YES;
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
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];

    if (newWindow) {
        if (self.status != ZFPlayerStateStopped) {
            self.ZFPlayerView_observingPlaybackTimeChanges = YES;
        }
        if (self.changeFullscreenModeWhenDeviceOrientationChanging) {
            self.observingOrientationChangeEvent = YES;
        }
    }
    else {
        self.observingOrientationChangeEvent = NO;

        // 从 view hierarchy 移除，需要暂停
        if (self.playerItem) {
            [self pause];
        }
        self.ZFPlayerView_observingPlaybackTimeChanges = NO;
    }
}

#pragma mark - 播放核心属性

@synthesize AVPlayer = _AVPlayer;

- (AVPlayer *)AVPlayer {
    if (!_AVPlayer) {
        AVPlayer *ap = [AVPlayer playerWithPlayerItem:self.playerItem];
        AVPlayerLayer *al = [AVPlayerLayer playerLayerWithPlayer:ap];
        [self.layer addSublayer:al];
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

    if (_playerItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
//        [_playerItem removeObserver:self forKeyPath:@"status"];
//        [_playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
//        [_playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
//        [_playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    }
    _playerItem = playerItem;
    if (playerItem) {
        [self.AVPlayer replaceCurrentItemWithPlayerItem:playerItem];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
//        [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
//        [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
//        // 缓冲区空了，需要等待数据
//        [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
//        // 缓冲区有足够数据可以播放了
//        [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)setVideoURL:(NSURL *)videoURL {
    if (self.playerItem) {
        [self resetPlayer];
    }

    self.playDidEnd   = NO;
    self.status = ZFPlayerStateStopped;

    self.playerItem  = [AVPlayerItem playerItemWithURL:videoURL];

    // 添加观察者、通知
    [self addObserverAndNotification];

    // 根据屏幕的方向设置相关UI
    [self onDeviceOrientationChange];

    // 本地文件不设置ZFPlayerStateBuffering状态
    if (videoURL.isFileURL) {
        self.status = ZFPlayerStatePlaying;
    } else {
        self.status = ZFPlayerStateBuffering;
    }

    // 开始播放
    [self play];
    self.controlView.startBtn.selected = YES;
    self.isPauseByUser = NO;

    _videoURL = videoURL;
}


- (void)play {
    [self.AVPlayer play];
}

- (void)pause {
    [self.AVPlayer pause];
}

- (void)resetPlayer {
    self.playerItem = nil;
    self.ZFPlayerView_observingPlaybackTimeChanges = NO;

    // 暂停
    [self pause];
    // 替换PlayerItem
    [self.AVPlayer replaceCurrentItemWithPlayerItem:nil];
    // 重置控制层View
    [self.controlView resetControlView];
}

- (void)seekToTime:(NSTimeInterval)time completion:(void (^)(BOOL))completion {
    // TODO: 合适的地方调用 cancelPendingSeeks
    CMTime tolerance = CMTimeFromNSTimeInterval(0.5);
    [self.AVPlayer seekToTime:CMTimeFromNSTimeInterval(time) toleranceBefore:tolerance toleranceAfter:tolerance completionHandler:^(BOOL finished) {
        if (completion) {
            completion(finished);
        }
    }];
}

#pragma mark 事件

- (void)moviePlayDidEnd:(NSNotification *)notification {
    self.status = ZFPlayerStateStopped;
    self.playDidEnd = YES;
}

- (void)appDidEnterBackground {
    [self pause];
    self.status = ZFPlayerStatePause;
}

- (void)appDidEnterPlayGround {
    if (!self.isPauseByUser) {
        self.status = ZFPlayerStatePlaying;
        self.controlView.startBtn.selected = YES;
        self.isPauseByUser = NO;
        [self play];
    }
}

/// 缓冲较差时候回调这里
- (void)bufferingSomeSecond {
    // playbackBufferEmpty会反复进入，因此在bufferingOneSecond延时播放执行完之前再调用bufferingSomeSecond都忽略
    __block BOOL isBuffering = NO;
    if (isBuffering) return;
    isBuffering = YES;

    // 需要先暂停一小会之后再播放，否则网络状况不好的时候时间在走，声音播放不出来
    [self pause];

    @weakify(self);
    dispatch_after_seconds(1, ^{
        @strongify(self);

        // 如果此时用户已经暂停了，则不再需要开启播放了
        if (self.isPauseByUser) {
            isBuffering = NO;
            return;
        }

        [self play];
        // 如果执行了play还是没有播放则说明还没有缓存好，则再次缓存一段时间
        isBuffering = NO;
        if (!self.playerItem.isPlaybackLikelyToKeepUp) {
            [self bufferingSomeSecond];
        }
    });
}

#pragma mark - 通知

- (void)addObserverAndNotification {
    // app退到后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
    // app进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayGround) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)setZFPlayerView_observingPlaybackTimeChanges:(BOOL)observingPlaybackTimeChanges {
    if (_ZFPlayerView_observingPlaybackTimeChanges == observingPlaybackTimeChanges) return;

    if (_ZFPlayerView_observingPlaybackTimeChanges) {
        if (self.ZFPlayerView_playbackTimeObserver) {
            [self.AVPlayer removeTimeObserver:self.ZFPlayerView_playbackTimeObserver];
        }
    }
    _ZFPlayerView_observingPlaybackTimeChanges = observingPlaybackTimeChanges;
    if (observingPlaybackTimeChanges) {
        self.ZFPlayerView_playbackTimeObserver = [self.AVPlayer addPeriodicTimeObserverForInterval:CMTimeFromNSTimeInterval(0.5) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            dout_float(NSTimeIntervalFromCMTime(time))
        }];
    }
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
        else if (ZFPlayerKeyIsEqual(keyPath, loadedTimeRanges)) {
            NSTimeInterval timeInterval = [self availableDuration];// 计算缓冲进度
            CMTime duration             = self.playerItem.duration;
            CGFloat totalDuration       = CMTimeGetSeconds(duration);
            [self.controlView.progressView setProgress:timeInterval / totalDuration animated:NO];
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

- (void)playerTimerAction {
    AVPlayer *player = self.AVPlayer;
    if (_playerItem.duration.timescale != 0) {
        self.controlView.videoSlider.value        = CMTimeGetSeconds([_playerItem currentTime]) / (_playerItem.duration.value / _playerItem.duration.timescale);//当前进度

        //当前时长进度progress
        NSInteger proMin = (NSInteger)CMTimeGetSeconds([player currentTime]) / 60;//当前秒
        NSInteger proSec = (NSInteger)CMTimeGetSeconds([player currentTime]) % 60;//当前分钟

        //duration 总时长
        NSInteger durMin = (NSInteger)_playerItem.duration.value / _playerItem.duration.timescale / 60;//总秒
        NSInteger durSec = (NSInteger)_playerItem.duration.value / _playerItem.duration.timescale % 60;//总分钟

        self.controlView.currentTimeLabel.text = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
        self.controlView.totalTimeLabel.text = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];
    }
}

- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[self.AVPlayer currentItem] loadedTimeRanges];
    CMTimeRange timeRange     = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds        = CMTimeGetSeconds(timeRange.start);
    float durationSeconds     = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result     = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

#pragma mark 屏幕旋转

- (void)setFullscreenMode:(BOOL)fullscreenMode {
    [self setFullscreenMode:fullscreenMode animated:NO];
}

- (void)setFullscreenMode:(BOOL)fullscreen animated:(BOOL)animated {
    _fullscreenMode = fullscreen;
    [self setDeviceOrientationToLandscape:fullscreen animated:animated];
    [self updateUIForFullscreenModeChanged];
    [self noticeDisplayerFullscreenModeChanged];
}

- (void)setLockOrientationWhenFullscreen:(BOOL)lockOrientationWhenFullscreen {
    _lockOrientationWhenFullscreen = lockOrientationWhenFullscreen;
    [self noticeDisplayerLockOrientationWhenFullscreenChanged];
}

/// 供用户设置，旋转时是否切换全屏
- (void)setChangeFullscreenModeWhenDeviceOrientationChanging:(BOOL)changeFullscreenModeWhenDeviceOrientationChanging {
    if (_changeFullscreenModeWhenDeviceOrientationChanging == changeFullscreenModeWhenDeviceOrientationChanging) return;
    _changeFullscreenModeWhenDeviceOrientationChanging = changeFullscreenModeWhenDeviceOrientationChanging;

    if (changeFullscreenModeWhenDeviceOrientationChanging) {
        if (self.window) {
            self.observingOrientationChangeEvent = YES;
        }
    }
    else {
        self.observingOrientationChangeEvent = NO;
    }
}

/// 旋转事件监听的管理
- (void)setObservingOrientationChangeEvent:(BOOL)observingOrientationChangeEvent {
    if (_observingOrientationChangeEvent != observingOrientationChangeEvent) {
        _observingOrientationChangeEvent = observingOrientationChangeEvent;
        if (observingOrientationChangeEvent) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDeviceOrientationChange) name:UIDeviceOrientationDidChangeNotification object:nil];
        }
        else {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
        }
    }

    // device 上这个破变量可能外面会管理，只能复杂点
    UIDevice *dv = [UIDevice currentDevice];
    if (observingOrientationChangeEvent) {
        if (!dv.generatesDeviceOrientationNotifications) {
            [dv beginGeneratingDeviceOrientationNotifications];
            self.deviceBeginGeneratingOrientationNotificationsChangedByMine = YES;
        }
    }
    else {
        if (dv.generatesDeviceOrientationNotifications
            && self.deviceBeginGeneratingOrientationNotificationsChangedByMine) {
            self.deviceBeginGeneratingOrientationNotificationsChangedByMine = NO;
            [dv endGeneratingDeviceOrientationNotifications];
        }
    }
}

/// 设备旋转事件的响应
- (void)onDeviceOrientationChange {
#if DEBUG
    NSAssert(self.changeFullscreenModeWhenDeviceOrientationChanging, @"不自动旋转不应走这里");
#endif

    if (self.fullscreenMode
        && self.lockOrientationWhenFullscreen) {
        // 全屏且锁定不变
        return;
    }

    BOOL isLandscape = UIInterfaceOrientationIsLandscape((UIInterfaceOrientation)[UIDevice currentDevice].orientation);
    if (self.fullscreenMode != isLandscape) {
        [self setFullscreenMode:isLandscape animated:YES];
    }
}

/// 全屏模式变更时更新界面
- (void)updateUIForFullscreenModeChanged {
    BOOL fullscreen = self.fullscreenMode;
    self.controlView.fullScreenBtn.selected = fullscreen;
    self.controlView.lockBtn.hidden = !fullscreen;
}

/// 工具方法，旋转设备
- (void)setDeviceOrientationToLandscape:(BOOL)isLandscape animated:(BOOL)animated {
    UIInterfaceOrientation orientation = (UIInterfaceOrientation)[UIDevice currentDevice].orientation;
    if (isLandscape) {
        if (!UIInterfaceOrientationIsLandscape(orientation)) {
            orientation = UIInterfaceOrientationLandscapeLeft;
        }
    }
    else {
        if (!UIInterfaceOrientationIsPortrait(orientation)) {
            orientation = UIInterfaceOrientationPortrait;
        }
    }
    [[UIDevice currentDevice] setOrientation:orientation animated:animated];
    //    [[UIApplication sharedApplication] setStatusBarOrientation:orientation animated:animated];
}

#pragma mark - Delegtate 通知

- (NSHashTable<id<ZFPlayerDisplayDelegate>> *)displayers {
    if (!_displayers) {
        _displayers = [NSHashTable weakObjectsHashTable];
    }
    return _displayers;
}

- (void)addDisplayer:(id<ZFPlayerDisplayDelegate>)displayer {
    if (displayer) {
        [self.displayers addObject:displayer];
    }
}

- (void)removeDisplayer:(id<ZFPlayerDisplayDelegate>)displayer {
    if (displayer) {
        [self.displayers removeObject:displayer];
    }
}

/**
 通知生成方法
 */
#define ZFPlayerDisplayerNoticeMethod(METHODNAME, PROTOCOL_SELECTOR) \
    - (void)METHODNAME {\
        NSArray *all = [self.displayers allObjects];\
        for (id<ZFPlayerDisplayDelegate> displayer in all) {\
            if ([displayer respondsToSelector:@selector(PROTOCOL_SELECTOR:)]) {\
                [displayer PROTOCOL_SELECTOR:self];\
            }\
        }\
    }

#define ZFPlayerDisplayerNoticeMethod2(METHODNAME, PROTOCOL_SELECTOR, PAR) \
    - (void)METHODNAME {\
        NSArray *all = [self.displayers allObjects];\
        for (id<ZFPlayerDisplayDelegate> displayer in all) {\
            if ([displayer respondsToSelector:@selector(ZFPlayer:PROTOCOL_SELECTOR:)]) {\
                [displayer ZFPlayer:self PROTOCOL_SELECTOR:PAR];\
            }\
        }\
    }


ZFPlayerDisplayerNoticeMethod(noticeDisplayerFullscreenModeChanged, ZFPlayerDidChangedFullscreenMode)
ZFPlayerDisplayerNoticeMethod(noticeDisplayerLockOrientationWhenFullscreenChanged, ZFPlayerDidChangedLockOrientationWhenFullscreen)

@end

