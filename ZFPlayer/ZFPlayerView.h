//
//  ZFPlayerView.h
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

#import <UIKit/UIKit.h>

typedef void(^ZFPlayerGoBackBlock)(void);

@interface ZFPlayerView : UIView

/** 视频URL */
@property (nonatomic, strong) NSURL               *videoURL;
/** 返回按钮Block */
@property (nonatomic, copy  ) ZFPlayerGoBackBlock goBackBlock;
/** palyer加到tableView */
@property (nonatomic, strong) UITableView         *tableView;
/** player所在cell的indexPath */
@property (nonatomic, strong) NSIndexPath         *indexPath;
/** ViewController中页面是否消失 */
@property (nonatomic, assign) BOOL                viewDisappear;
/** 是否在cell上播放video */
@property (nonatomic, assign) BOOL                isCellVideo;


/**
 *  取消延时隐藏controlView的方法,在ViewController的delloc方法中调用
 *  用于解决：刚打开视频播放器，就关闭该页面，maskView的延时隐藏还未执行。
 */
- (void)cancelAutoFadeOutControlBar;

/**
 *  类方法创建，该方法适用于代码创建View
 *
 *  @return ZFPlayer
 */
+ (instancetype)setupZFPlayer;
/**
 *  单例，用于列表cell上多个视频
 *
 *  @return ZFPlayer
 */
+ (instancetype)playerView;

/**
 *  player添加到cell上
 *
 *  @param cell 添加player的cellImageView
 */
- (void)addPlayerToCellImageView:(UIImageView *)imageView;

/**
 *  重置player
 */
- (void)resetPlayer;

/** 
 *  播放
 */
- (void)play;

/** 
  * 暂停 
 */
- (void)pause;

/**
 *  用于cell上播放player
 *
 *  @param videoURL  视频的URL
 *  @param tableView tableView
 *  @param indexPath indexPath 
 *  @param ImageViewTag ImageViewTag
 */
- (void)setVideoURL:(NSURL *)videoURL
      withTableView:(UITableView *)tableView
        AtIndexPath:(NSIndexPath *)indexPath
   withImageViewTag:(NSInteger)tag;

#pragma mark - UI

/** 快进快退label */
@property (nonatomic, weak) IBOutlet UILabel *horizontalLabel;
/** 系统菊花 */
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activity;
/** 返回按钮*/
@property (nonatomic, weak) IBOutlet UIButton *backBtn;
/** 重播按钮 */
@property (nonatomic, weak) IBOutlet UIButton *repeatBtn;

@end
