//
//  ZFPlayerControlView.h
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

#import "RFUI.h"
#import "ZFPlayerView.h"

@interface ZFPlayerControlView : UIView <
    RFInitializing,
    UIGestureRecognizerDelegate,
    ZFPlayerDisplayDelegate
>

@property (nonatomic, weak) ZFPlayerView *player;

/** 重置ControlView */
- (void)resetControlView;

@property (nonatomic, weak) IBOutlet UIImageView *bottomImageView;
@property (nonatomic, weak) IBOutlet UIImageView *topImageView;

/** 开始播放按钮 */
@property (nonatomic, weak) IBOutlet UIButton *startBtn;
/** 当前播放时长label */
@property (nonatomic, weak) IBOutlet UILabel *currentTimeLabel;
/** 视频总时长label */
@property (nonatomic, weak) IBOutlet UILabel *totalTimeLabel;
/** 缓冲进度条 */
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
/** 滑杆 */
@property (nonatomic, weak) IBOutlet UISlider *videoSlider;


/** 全屏按钮 */
@property (nonatomic, weak) IBOutlet UIButton *fullScreenBtn;

- (IBAction)onFullscreenButtonTapped:(UIButton *)sender;

/** 锁定屏幕方向按钮 */
@property (nonatomic, weak) IBOutlet UIButton *lockBtn;

- (IBAction)onOrientationLockButtonTapped:(UIButton *)sender;

/** 快进快退label */
@property (nonatomic, weak) IBOutlet UILabel *horizontalLabel;
/** 系统菊花 */
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activity;
/** 返回按钮*/
@property (nonatomic, weak) IBOutlet UIButton *backBtn;
/** 重播按钮 */
@property (nonatomic, weak) IBOutlet UIButton *repeatBtn;


@end
