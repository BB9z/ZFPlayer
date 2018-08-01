/*!
 ZFPlayerControlView
 
 Copyright © 2016, 2018 BB9z.
 Copyright © 2016 任子丰 http://github.com/renzifeng
 https://github.com/BB9z/ZFPlayer
 
 The MIT License (MIT)
 http://www.opensource.org/licenses/mit-license.php
 */

#import "ZFPlayerView.h"

@class ZFPlayerLoadedRangeProgressView;

@interface ZFPlayerControlView : UIView <
    RFInitializing,
    ZFPlayerDisplayDelegate
>

@property (nonatomic, weak) IBOutlet ZFPlayerView *player;

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
@property (nonatomic, weak) IBOutlet UIView *floatMessageContainer;
@property (nonatomic, weak) IBOutlet UILabel *floatMessageLabel;

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activity;

@property (nonatomic, weak) IBOutlet UIButton *replayButton;
@end
