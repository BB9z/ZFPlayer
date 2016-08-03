//
//  ZFPlayerControlView.m
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

#import "ZFPlayerControlView.h"
#import "ZFPlayerLoadedRangeProgressView.h"
@import MediaPlayer;

static const CGFloat ZFPlayerAnimationTimeInterval             = 7.0f;
static const CGFloat ZFPlayerControlBarAutoFadeOutTimeInterval = 0.5f;

// 枚举值，包含水平移动方向和垂直移动方向
typedef NS_ENUM(NSInteger, PanDirection){
    PanDirectionHorizontalMoved, //横向移动
    PanDirectionVerticalMoved    //纵向移动
};

@interface ZFPlayerControlView ()
@property (nonatomic) BOOL isMaskShowing;

/** 计时器 */
@property (nonatomic, strong) NSTimer *timer;

/** 定义一个实例变量，保存枚举值 */
@property (nonatomic, assign) PanDirection panDirection;

/** 是否在调节音量*/
@property (nonatomic, assign) BOOL isVolume;

/** slider上次的值 */
@property (nonatomic, assign) CGFloat sliderLastValue;

/** 用来保存快进的总时长 */
@property (nonatomic, assign) NSTimeInterval sumTime;

@property (nonatomic) BOOL playbackProgressChanging;
@end

@implementation ZFPlayerControlView
RFInitializingRootForUIView

- (void)onInit {
    douto(self.videoSlider)
}

- (void)afterInit {
    // Nothing
}

- (void)awakeFromNib {
    [super awakeFromNib];

    self.lockBtn.hidden = YES;
    [self.videoSlider setThumbImage:[UIImage imageNamed:@"ZFPlayer.slider"] forState:UIControlStateNormal];
    [self resetControlView];
}

- (void)dealloc {
    //NSLog(@"%@释放了",self.class);
}

/** 重置ControlView */
- (void)resetControlView {
    self.videoSlider.value = 0;
    self.videoSlider.maximumValue = 1;
    self.loadRangView.item = nil;
    self.currentTimeLabel.text = @"00:00";
    self.totalTimeLabel.text = @"00:00";
}

- (IBAction)onFullscreenButtonTapped:(UIButton *)sender {
//    [self.player setFullscreenMode:!sender.selected animated:YES];
}

- (void)ZFPlayerDidChangedFullscreenMode:(ZFPlayerView *)player {
//    self.fullScreenBtn.selected = player.fullscreenMode;
}

- (IBAction)onOrientationLockButtonTapped:(UIButton *)sender {
//    self.player.lockOrientationWhenFullscreen = !sender.selected;
}

- (void)ZFPlayerDidChangedLockOrientationWhenFullscreen:(ZFPlayerView *)player {
//    self.lockBtn.selected = player.lockOrientationWhenFullscreen;
}

- (IBAction)repeatPlay:(UIButton *)sender {
    self.repeatBtn.hidden = YES;
    [self.player resetPlayer];
    [self.player setVideoURL:self.player.videoURL];
}

- (IBAction)onPlayButtonTapped:(UIButton *)button {
    button.selected = !button.selected;
    // TODO: 状态恢复
//    self.player.isPauseByUser = !button.isSelected;
    if (button.selected) {
        [self.player play];
//        self.player.state = ZFPlayerStatePlaying;
    } else {
        [self.player pause];
//        self.player.state = ZFPlayerStatePause;
    }
}

- (IBAction)onBackButtonTapped:(id)sender {
//    if (self.fullscreenMode) {
//        [self setFullscreenMode:NO animated:YES];
//        return;
//    }
//
//    // player加到控制器上，只有一个player时候
//    [self.timer invalidate];
//    self.timer = nil;
    [self.player pause];
}

#pragma mark - 播放进度控制

//    // slider开始滑动事件
//    [self.controlView.videoSlider addTarget:self action:@selector(progressSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
//    // slider滑动中事件
//    [self.controlView.videoSlider addTarget:self action:@selector(progressSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
//    // slider结束滑动事件
//    [self.controlView.videoSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];

- (IBAction)onPlaybackProgressSliderTouchBegin:(id)sender {

}

/**
 *  slider开始滑动事件
 *
 *  @param slider UISlider
 */
- (void)progressSliderTouchBegan:(UISlider *)slider {
    if (self.player.status == AVPlayerStatusReadyToPlay) {
        self.playbackProgressChanging = YES;
    }
}

/**
 *  slider滑动中事件
 *
 *  @param slider UISlider
 */
- (void)progressSliderValueChanged:(UISlider *)slider {
    //拖动改变视频播放进度
    if (self.player.status == AVPlayerStatusReadyToPlay) {
        NSString *style = @"";
        CGFloat value = slider.value - self.sliderLastValue;
        if (value > 0) {
            style = @">>";
        } else if (value < 0) {
            style = @"<<";
        }
        self.sliderLastValue = slider.value;

        [self.player pause];
        //计算出拖动的当前秒数
        CGFloat total = (CGFloat)self.player.playerItem.duration.value / self.player.playerItem.duration.timescale;

        NSInteger dragedSeconds = floorf(total * slider.value);

        //转换成CMTime才能给player来控制播放进度

        CMTime dragedCMTime = CMTimeMake(dragedSeconds, 1);
        // 拖拽的时长
        NSInteger proMin = (NSInteger)CMTimeGetSeconds(dragedCMTime) / 60;//当前秒
        NSInteger proSec = (NSInteger)CMTimeGetSeconds(dragedCMTime) % 60;//当前分钟

        //duration 总时长
        NSInteger durMin = (NSInteger)total / 60;//总秒
        NSInteger durSec = (NSInteger)total % 60;//总分钟

        NSString *currentTime = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
        NSString *totalTime = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];

        if (durSec > 0) {
            // 当总时长>0时候才能拖动slider
            self.currentTimeLabel.text = currentTime;
            self.horizontalLabel.hidden            = NO;
            self.horizontalLabel.text              = [NSString stringWithFormat:@"%@ %@ / %@",style, currentTime, totalTime];
        }
        else {
            // 此时设置slider值为0
            slider.value = 0;
        }

    }
    else { // player状态加载失败
        // 此时设置slider值为0
        slider.value = 0;
    }
}

- (void)progressSliderTouchEnded:(UISlider *)slider {
    if (self.player.status == AVPlayerStatusReadyToPlay) {

        // 继续开启timer
        [self.timer setFireDate:[NSDate date]];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.horizontalLabel.hidden = YES;
        });
        // 结束滑动时候把开始播放按钮改为播放状态
        self.startBtn.selected = YES;
        self.player.isPauseByUser = NO;

        // 滑动结束延时隐藏controlView
        [self autoFadeOutControlBar];

        //计算出拖动的当前秒数
        CGFloat total = (CGFloat)self.player.playerItem.duration.value / self.player.playerItem.duration.timescale;

        double dragedSeconds = floorf(total * slider.value);
        [self.player seekToTime:dragedSeconds completion:^(BOOL finished) {
            if (self.player.isPauseByUser) {
                return;
            }
            [self.player play];
            if (!self.player.playerItem.playbackLikelyToKeepUp) {
                self.player.status = ZFPlayerStateBuffering;
            }
        }];
    }
}

#pragma mark -

- (void)hideControlView {
    if (!self.isMaskShowing) {
        return;
    }
    [UIView animateWithDuration:ZFPlayerControlBarAutoFadeOutTimeInterval animations:^{
        self.alpha = 0.5;
    }completion:^(BOOL finished) {
        self.isMaskShowing = NO;
    }];
}

- (void)animateShow {
    if (self.isMaskShowing) {
        return;
    }
    [UIView animateWithDuration:ZFPlayerControlBarAutoFadeOutTimeInterval animations:^{
        self.backBtn.alpha = 1;
        if (self.player.playDidEnd) { // 播放完了
            self.alpha = 0.5;
        }else {
            self.alpha = 1;
        }
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    } completion:^(BOOL finished) {
        self.isMaskShowing = YES;
        [self autoFadeOutControlBar];
    }];
}

- (void)autoFadeOutControlBar {
    if (!self.isMaskShowing) {
        return;
    }
    __weak __typeof(&*self)weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ZFPlayerAnimationTimeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        if (strongSelf.isMaskShowing) {
            [strongSelf hideControlView];
        }
    });
}

- (void)createGesture {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [self addGestureRecognizer:tap];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGPoint point = [touch locationInView:self];
    // （屏幕下方slider区域不响应pan手势）
    if ((point.y > self.bounds.size.height-40)) {
        return NO;
    }
    return YES;
}

- (void)tapAction:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        if (self.isMaskShowing) {
            [self hideControlView];
        } else {
            [self animateShow];
        }
    }
}

- (void)panDirection:(UIPanGestureRecognizer *)pan {
    //根据在view上Pan的位置，确定是调音量还是亮度
    CGPoint locationPoint = [pan locationInView:self];

    // 我们要响应水平移动和垂直移动
    // 根据上次和本次移动的位置，算出一个速率的point
    CGPoint veloctyPoint = [pan velocityInView:self];

    // 判断是垂直移动还是水平移动
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:{ // 开始移动
            // 使用绝对值来判断移动的方向
            CGFloat x = fabs(veloctyPoint.x);
            CGFloat y = fabs(veloctyPoint.y);
            if (x > y) { // 水平移动
                self.panDirection           = PanDirectionHorizontalMoved;
                // 取消隐藏
                self.horizontalLabel.hidden = NO;
                // 给sumTime初值
                CMTime time = self.player.playerItem.currentTime;
                self.sumTime = time.value/time.timescale;

                // 暂停视频播放
                [self.player pause];
                // 暂停timer
                [self.timer setFireDate:[NSDate distantFuture]];
            }
            else if (x < y){ // 垂直移动
                self.panDirection = PanDirectionVerticalMoved;
                // 开始滑动的时候,状态改为正在控制音量
                if (locationPoint.x > self.bounds.size.width / 2) {
                    self.isVolume = YES;
                }
                else { // 状态改为显示亮度调节
                    self.isVolume = NO;
                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged:{ // 正在移动
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved:{
                    [self horizontalMoved:veloctyPoint.x]; // 水平移动的方法只要x方向的值
                    break;
                }
                case PanDirectionVerticalMoved:{
                    [self verticalMoved:veloctyPoint.y]; // 垂直移动方法只要y方向的值
                    break;
                }
                default:
                    break;
            } // END self.panDirection switch
            break;
        }
        case UIGestureRecognizerStateEnded:{ // 移动停止
            // 移动结束也需要判断垂直或者平移
            // 比如水平移动结束时，要快进到指定位置，如果这里没有判断，当我们调节音量完之后，会出现屏幕跳动的bug
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved:{

                    // 继续播放
                    [self.player play];
                    [self.timer setFireDate:[NSDate date]];

                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        // 隐藏视图
                        self.horizontalLabel.hidden = YES;
                    });
                    //快进、快退时候把开始播放按钮改为播放状态
                    self.startBtn.selected = YES;
                    self.player.isPauseByUser = NO;

                    [self.player seekToTime:self.sumTime completion:^(BOOL finished) {
                        if (self.player.isPauseByUser) {
                            return;
                        }
                        [self.player play];
                        if (!self.player.playerItem.playbackLikelyToKeepUp) {
                            self.player.status = ZFPlayerStateBuffering;
                        }
                    }];
                    self.sumTime = 0;
                    break;
                }
                case PanDirectionVerticalMoved:{
                    // 垂直移动结束后，把状态改为不再控制音量
                    self.isVolume = NO;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        self.horizontalLabel.hidden = YES;
                    });
                    break;
                }
                default:
                    break;
            } // END self.panDirection switch
            break;
        }
        default:
            break;
    } // END pan.state switch
}

- (void)verticalMoved:(CGFloat)value {
    if (self.isVolume) {
        // TODO: 暴漏 AVPlayer 直接修改音量
        MPMusicPlayerController *vpc = [MPMusicPlayerController applicationMusicPlayer];
        vpc.volume = value / 10000; // 越小幅度越小
    }
    else {
        //亮度
        [UIScreen mainScreen].brightness -= value / 10000;
    }
}

- (void)horizontalMoved:(CGFloat)value {
    // 快进快退的方法
    NSString *style = @"";
    if (value < 0) {
        style = @"<<";
    }
    else if (value > 0){
        style = @">>";
    }

    // 每次滑动需要叠加时间
    self.sumTime += value / 200;

    // 需要限定sumTime的范围
    CMTime totalTime = self.player.playerItem.duration;
    CGFloat totalMovieDuration = (CGFloat)totalTime.value/totalTime.timescale;
    if (self.sumTime > totalMovieDuration) {
        self.sumTime = totalMovieDuration;
    }else if (self.sumTime < 0){
        self.sumTime = 0;
    }

    NSString *nowTime = [self durationMSStringWithTimeInterval:self.sumTime];
    NSString *durationTime = [self durationMSStringWithTimeInterval:totalMovieDuration];
    self.horizontalLabel.text = [NSString stringWithFormat:@"%@ %@ / %@",style, nowTime, durationTime];
}

- (NSString *)durationMSStringWithTimeInterval:(NSTimeInterval)duration {
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)duration/60, (long)duration % 60];
}

- (void)ZFPlayerDidUpdatePlaybackInfo:(ZFPlayerView *)player {
    _douto(player)
    if (!self.loadRangView.item) {
        self.loadRangView.item = player.playerItem;
    }
    [self.loadRangView setNeedsDisplay];

    self.currentTimeLabel.text = [self durationMSStringWithTimeInterval:player.currentTime];
    self.totalTimeLabel.text = [self durationMSStringWithTimeInterval:player.duration];
}

@end
