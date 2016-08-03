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
#import "RFTimer.h"
@import MediaPlayer;

static const CGFloat ZFPlayerAnimationTimeInterval             = 7.0f;
static const CGFloat ZFPlayerControlBarAutoFadeOutTimeInterval = 0.5f;

// 枚举值，包含水平移动方向和垂直移动方向
typedef NS_ENUM(NSInteger, PanDirection){
    PanDirectionHorizontalMoved, //横向移动
    PanDirectionVerticalMoved    //纵向移动
};

@interface ZFPlayerControlView ()
@property (nonatomic, strong) RFTimer *autoHidePanelTimer;

/** 定义一个实例变量，保存枚举值 */
@property (nonatomic, assign) PanDirection panDirection;

/** 是否在调节音量*/
@property (nonatomic, assign) BOOL isVolume;

/** 用来保存快进的总时长 */
@property (nonatomic, assign) NSTimeInterval sumTime;

@property (nonatomic) BOOL playbackProgressChanging;
@property (nonatomic) double seekBeginValue;
@end

@implementation ZFPlayerControlView
RFInitializingRootForUIView

- (void)onInit {
}

- (void)afterInit {
}

- (void)awakeFromNib {
    [super awakeFromNib];

    [self.playbackProgressSlider setThumbImage:[UIImage imageNamed:@"ZFPlayer.slider"] forState:UIControlStateNormal];
    [self resetControlView];
}

- (void)resetControlView {
    self.playbackProgressSlider.value = 0;
    self.playbackProgressSlider.minimumValue = 0;
    self.playbackProgressSlider.maximumValue = 1;

    self.loadRangView.item = nil;
    self.replayButton.hidden = YES;
    self.seekProgressIndicatorContainer.hidden = YES;
    [self updateProgressUIWithCurrentTime:0 duration:0 skipSlider:NO];
}

- (IBAction)onPlayButtonTapped:(UIButton *)button {
    button.selected = !button.selected;
    self.player.paused = button.selected;
}

- (IBAction)onBackButtonTapped:(id)sender {
    self.player.paused = YES;
}

- (IBAction)onReplayButtonTapped:(id)sender {
    self.replayButton.hidden = YES;
    [self.player seekToTime:0 completion:^(BOOL finished) {
        [self.player play];
    }];
}

#pragma mark - 面板显隐

- (BOOL)panelHidden {
    return self.toolBar.hidden;
}

- (void)setPanelHidden:(BOOL)panelHidden {
    [self setPanelHidden:panelHidden animated:NO];
}

- (void)setPanelHidden:(BOOL)hidden animated:(BOOL)animated {
    NSArray<UIView *> *panelViews = self.panelElementViews;
    if (!hidden) {
        for (UIView *v in panelViews) {
            v.hidden = NO;
        }
    }
    [UIView animateWithDuration:ZFPlayerControlBarAutoFadeOutTimeInterval delay:0 options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState animated:animated beforeAnimations:^{
        for (UIView *v in panelViews) {
            v.alpha = hidden? 1 : 0;
        }
    } animations:^{
        for (UIView *v in panelViews) {
            v.alpha = hidden? 0 : 1;
        }
    } completion:^(BOOL finished) {
        if (finished) {
            for (UIView *v in panelViews) {
                v.hidden = hidden;
            }
        }
    }];

    if (!hidden) {
        [self resetAutoHidePanelTimer];
    }
}

- (IBAction)onTapInView:(id)sender {
    [self setPanelHidden:!self.panelHidden animated:YES];
}

- (RFTimer *)autoHidePanelTimer {
    if (!_autoHidePanelTimer) {
        @weakify(self);
        _autoHidePanelTimer = [RFTimer scheduledTimerWithTimeInterval:4 repeats:NO fireBlock:^(RFTimer *timer, NSUInteger repeatCount) {
            @strongify(self);
            if (!self.panelHidden
                && self.player.isPlaying) {
                [self setPanelHidden:YES animated:YES];
            }
        }];
    }
    return _autoHidePanelTimer;
}

- (void)resetAutoHidePanelTimer {
    self.autoHidePanelTimer.suspended = YES;
    self.autoHidePanelTimer.suspended = NO;
}

#pragma mark - 播放进度控制

- (IBAction)onPlaybackProgressSliderTouchDown:(UISlider *)sender {
    self.seekBeginValue = sender.value;
    self.autoHidePanelTimer.suspended = YES;
}

- (IBAction)onPlaybackProgressSliderTouchMove:(UISlider *)sender {
    NSTimeInterval duration = self.player.duration;
    NSTimeInterval target = sender.value * duration;
    [self updateProgressUIWithCurrentTime:target duration:duration skipSlider:YES];
    self.autoHidePanelTimer.suspended = NO;
}

- (IBAction)onPlaybackProgressSliderTouchUp:(UISlider *)sender {
    NSTimeInterval duration = self.player.duration;
    NSTimeInterval target = sender.value * duration;
    [self.player seekToTime:target completion:^(BOOL finished) {
        self.seekBeginValue = 0;
    }];
    [self updateProgressUIWithCurrentTime:target duration:duration skipSlider:YES];
    self.autoHidePanelTimer.suspended = NO;
}

- (IBAction)onPlaybackProgressSliderTouchCancel:(id)sender {
    self.seekBeginValue = 0;
    [self ZFPlayerDidUpdatePlaybackInfo:self.player];
}

- (void)updateProgressUIWithCurrentTime:(NSTimeInterval)current duration:(NSTimeInterval)duration skipSlider:(BOOL)skipSlider {
    self.currentTimeLabel.text = [self durationMSStringWithTimeInterval:current];
    self.totalTimeLabel.text = [self durationMSStringWithTimeInterval:duration];
    [self setProgressControlEnabled:(duration != 0) animated:YES];

    if (skipSlider) return;
    if (duration > 0) {
        [self.playbackProgressSlider setValue:current/duration animated:YES];
    }
    else {
        self.playbackProgressSlider.value = 0;
    }
}

- (void)setProgressControlEnabled:(BOOL)enabled animated:(BOOL)animated {
    if (self.playbackProgressSlider.enabled == enabled) return;

    self.playbackProgressSlider.enabled = enabled;
    self.progressContainer.userInteractionEnabled = enabled;
}

- (NSString *)durationMSStringWithTimeInterval:(NSTimeInterval)duration {
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)duration/60, (long)duration % 60];
}

#pragma mark -

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

                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        // 隐藏视图
                        self.horizontalLabel.hidden = YES;
                    });
                    //快进、快退时候把开始播放按钮改为播放状态
                    self.startBtn.selected = YES;
                    self.player.paused = NO;

                    [self.player seekToTime:self.sumTime completion:^(BOOL finished) {
                        if (self.player.paused) {
                            return;
                        }
                        [self.player play];
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

#pragma mark -

- (void)ZFPlayerDidUpdatePlaybackInfo:(ZFPlayerView *)player {
    if (self.seekBeginValue) {
        // 正在调解进度，UI 受手势影响
        return;
    }
    [self updateProgressUIWithCurrentTime:player.currentTime duration:player.duration skipSlider:NO];
}

- (void)ZFPlayer:(ZFPlayerView *)player didChangePlayerItem:(AVPlayerItem *)playerItem {
    self.loadRangView.item = player.playerItem;
    [self updateProgressUIWithCurrentTime:player.currentTime duration:player.duration skipSlider:NO];
    [self setPanelHidden:NO animated:YES];
}

- (void)ZFPlayerDidPlayToEnd:(ZFPlayerView *)player {
    [self setPanelHidden:YES animated:YES];
    self.replayButton.hidden = NO;
}

@end
