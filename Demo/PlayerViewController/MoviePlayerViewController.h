/*!
 MoviePlayerViewController
 
 Copyright © 2016, 2018 BB9z.
 Copyright © 2016 任子丰 http://github.com/renzifeng
 https://github.com/BB9z/ZFPlayer
 
 The MIT License (MIT)
 http://www.opensource.org/licenses/mit-license.php
 */
#import <UIKit/UIKit.h>

@class ZFPlayerView;

/**
 演示 vc
 
 提供错误处理和全屏模式的参考
 */
@interface MoviePlayerViewController : UIViewController
@property (nonatomic, weak) IBOutlet ZFPlayerView *playerView;

@property NSURL *videoURL;
@property BOOL autoPlay;

@property (weak) IBOutlet UILabel *errorLabel;

@property (weak) IBOutlet UIView *screenshotContainer;
@property (weak) IBOutlet UIImageView *screenshotImageView;

#pragma mark - 全屏模式

@property BOOL lockFullscreen;

@end
