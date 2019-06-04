/*!
 ZFPlayerControlView
 
 Copyright © 2016, 2018-2019 BB9z.
 Copyright © 2016 任子丰 http://github.com/renzifeng
 https://github.com/BB9z/ZFPlayer
 
 The MIT License (MIT)
 http://www.opensource.org/licenses/mit-license.php
 */

#import "ZFPlayerView.h"

@class ZFPlayerLoadedRangeProgressView;

/**
 随 ZFPlayerView 默认提供的控制 UI
 
 因为业务千变万化，没精力考虑所有情况，也会导致过于臃肿，
 这个 UI 只覆盖基本功能，接口设计未考虑子类重写。
 
 实际项目使用时，如果功能基本满足，可直接用或子类；如果需求差距大，建议参考另写。
 */
@interface ZFPlayerControlView : UIView <
    RFInitializing,
    ZFPlayerDisplayDelegate
>

@property (nonatomic, weak) IBOutlet ZFPlayerView *player;

@property (nonatomic) BOOL panelHidden;
- (void)setPanelHidden:(BOOL)hidden animated:(BOOL)animated;

/// 集合内指定的 view 均属于面板元素，显隐受 panelHidden 控制
@property (strong) IBOutletCollection(UIView) NSArray *panelElementViews;

@property (weak) IBOutlet UIButton *navigationBackButton;

@property (weak) IBOutlet UIView *toolBar;

@property (weak) IBOutlet UIButton *startPauseButton;

/// 进度显示，控制部分的容器
@property (weak) IBOutlet UIView *progressContainer;
@property (weak) IBOutlet UILabel *currentTimeLabel;
/// 已加载进度
@property (weak) IBOutlet ZFPlayerLoadedRangeProgressView *loadRangView;
/// 播放进度
@property (weak) IBOutlet UISlider *playbackProgressSlider;
@property (weak) IBOutlet UILabel *totalTimeLabel;
@property (weak) IBOutlet UIButton *fullScreenButton;

///
@property (weak) IBOutlet UIView *floatMessageContainer;
@property (weak) IBOutlet UILabel *floatMessageLabel;

@property (weak) IBOutlet UIActivityIndicatorView *activity;

@property (weak) IBOutlet UIButton *replayButton;
@end
