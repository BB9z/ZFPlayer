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

@interface ZFPlayerControlView ()
@end

@implementation ZFPlayerControlView

/** 类方法创建 */
+ (instancetype)setupPlayerControlView {
    return [[NSBundle mainBundle] loadNibNamed:@"ZFPlayerControlView" owner:nil options:nil].lastObject;
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
    self.progressView.progress = 0;
    self.currentTimeLabel.text = @"00:00";
    self.totalTimeLabel.text = @"00:00";
}

- (IBAction)onFullscreenButtonTapped:(UIButton *)sender {
    [self.player setFullscreenMode:!sender.selected animated:YES];
}

- (void)ZFPlayerDidChangedFullscreenMode:(ZFPlayerView *)player {
    self.fullScreenBtn.selected = player.fullscreenMode;
}

- (IBAction)onOrientationLockButtonTapped:(UIButton *)sender {
    self.player.lockOrientationWhenFullscreen = !sender.selected;
}

- (void)ZFPlayerDidChangedLockOrientationWhenFullscreen:(ZFPlayerView *)player {
    self.lockBtn.selected = player.lockOrientationWhenFullscreen;
}

@end
