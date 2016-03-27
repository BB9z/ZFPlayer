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
#import "ZFPlayer.h"

@interface ZFPlayerControlView ()
@end

@implementation ZFPlayerControlView

/** 类方法创建 */
+ (instancetype)setupPlayerControlView {
    return [[NSBundle mainBundle] loadNibNamed:@"ZFPlayerControlView" owner:nil options:nil].lastObject;
}

- (void)dealloc {
    //NSLog(@"%@释放了",self.class);
}

- (void)awakeFromNib {
    // 默认隐藏锁定按钮
    self.lockBtn.hidden = YES;
    // 设置slider
    [self.videoSlider setThumbImage:[UIImage imageNamed:@"ZFPlayer.slider"] forState:UIControlStateNormal];
    
    [self insertSubview:self.progressView belowSubview:self.videoSlider];
    self.videoSlider.minimumTrackTintColor = [UIColor whiteColor];
    self.videoSlider.maximumTrackTintColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.6];

    self.progressView.progressTintColor    = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.3];
    self.progressView.trackTintColor       = [UIColor clearColor];
}

/** 重置ControlView */
- (void)resetControlView {
    self.videoSlider.value = 0;
    self.progressView.progress = 0;
    self.currentTimeLabel.text = @"00:00";
    self.totalTimeLabel.text = @"00:00";
}

@end
