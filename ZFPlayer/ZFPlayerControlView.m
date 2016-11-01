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


static const CGFloat ZFPlayerControlBarAutoFadeOutTimeInterval = 0.5f;

@interface ZFPlayerControlView ()
@property (nonatomic, strong) RFTimer *autoHidePanelTimer;
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
    self.playbackProgressSlider.value = 0;
    self.playbackProgressSlider.minimumValue = 0;
    self.playbackProgressSlider.maximumValue = 1;

    [self ZFPlayer:self.player didChangePlayerItem:self.player.playerItem];
    self.replayButton.hidden = YES;
    self.seekProgressIndicatorContainer.hidden = YES;
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

- (void)layoutSubviews {
    [super layoutSubviews];
    self.fullScreenBtn.selected = self.player.shouldApplyFullscreenLayout;
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

#pragma mark - 开始/暂停

- (IBAction)onPlayButtonTapped:(UIButton *)button {
    self.player.paused = self.player.isPlaying;
}

- (void)ZFPlayer:(ZFPlayerView *)player didChangePauseState:(BOOL)isPaused {
    self.startPauseButton.selected = !isPaused;
    if (isPaused) {
        [self setPanelHidden:NO animated:YES];
    }
    else {
        [self resetAutoHidePanelTimer];
        self.replayButton.hidden = YES;
    }
    [self updateActivityUI];
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
    if (self.playbackProgressSlider.hidden == !enabled) return;

    self.playbackProgressSlider.userInteractionEnabled = enabled;
    self.playbackProgressSlider.hidden = !enabled;
}

- (NSString *)durationMSStringWithTimeInterval:(NSTimeInterval)duration {
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)duration/60, (long)duration % 60];
}

#pragma mark - 加载状态

- (void)updateActivityUI {
    BOOL shouldShowLoading = self.player.buffering && !self.player.isPlaying;
    if (shouldShowLoading != self.activity.isAnimating) {
        if (shouldShowLoading) {
            [self.activity startAnimating];
        }
        else {
            [self.activity stopAnimating];
        }
    }
}

#pragma mark -

- (void)ZFPlayerDidUpdatePlaybackInfo:(ZFPlayerView *)player {
    if (self.seekBeginValue) {
        // 正在调解进度，UI 受手势影响
        return;
    }
    [self updateProgressUIWithCurrentTime:player.currentTime duration:player.duration skipSlider:NO];
    [self updateActivityUI];
}

- (void)ZFPlayer:(ZFPlayerView *)player didChangePlayerItem:(AVPlayerItem *)playerItem {
    self.startPauseButton.enabled = !!playerItem;
    self.loadRangView.item = player.playerItem;
    [self updateProgressUIWithCurrentTime:player.currentTime duration:player.duration skipSlider:NO];
    [self setPanelHidden:NO animated:YES];
}

- (void)ZFPlayerDidPlayToEnd:(ZFPlayerView *)player {
    [self setPanelHidden:YES animated:YES];
    self.replayButton.hidden = NO;
}

@end
