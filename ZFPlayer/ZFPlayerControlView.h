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

@class ZFPlayerLoadedRangeProgressView;

@interface ZFPlayerControlView : UIView <
    RFInitializing,
    ZFPlayerDisplayDelegate
>

@property (nonatomic, weak) ZFPlayerView *player;

@property (nonatomic) BOOL panelHidden;
- (void)setPanelHidden:(BOOL)hidden animated:(BOOL)animated;

/// 集合内指定的 view 均属于面板元素，显隐受 panelHidden 控制
@property (nonatomic, strong) IBOutletCollection(UIView) NSArray *panelElementViews;

@property (nonatomic, weak) IBOutlet UIButton *navigationBackButton;

@property (nonatomic, weak) IBOutlet UIView *toolBar;

@property (nonatomic, weak) IBOutlet UIButton *startPauseButton;

/// 进度显示，控制部分的容器
@property (nonatomic, weak) IBOutlet UIView *progressContainer;
@property (nonatomic, weak) IBOutlet UILabel *currentTimeLabel;
/// 已加载进度
@property (nonatomic, weak) IBOutlet ZFPlayerLoadedRangeProgressView *loadRangView;
/// 播放进度
@property (nonatomic, weak) IBOutlet UISlider *playbackProgressSlider;
@property (nonatomic, weak) IBOutlet UILabel *totalTimeLabel;
@property (nonatomic, weak) IBOutlet UIButton *fullScreenBtn;

///
@property (nonatomic, weak) IBOutlet UIView *seekProgressIndicatorContainer;
@property (nonatomic, weak) IBOutlet UILabel *horizontalLabel;

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activity;

@property (nonatomic, weak) IBOutlet UIButton *replayButton;
@end
