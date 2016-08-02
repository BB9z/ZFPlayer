//
//  MoviePlayerViewController.h
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

@class ZFPlayerView;

@interface MoviePlayerViewController : UIViewController
@property (weak, nonatomic) IBOutlet ZFPlayerView *playerView;

@property (nonatomic, strong) NSURL *videoURL;
@property (nonatomic) BOOL autoPlay;
@property (nonatomic) BOOL shouldHideNavigationBar;

#pragma mark - 全屏模式

@property (nonatomic) BOOL lockFullscreen;

/// 全屏时锁定屏幕方向
@property (nonatomic, getter=isLockOrientationWhenFullscreen) BOOL lockOrientationWhenFullscreen;

/// 设备旋转时自动切换全屏模式，默认 YES
@property (nonatomic) BOOL changeFullscreenModeWhenDeviceOrientationChanging;

/// 控制是否监听屏幕旋转事件
@property (nonatomic) BOOL observingOrientationChangeEvent;
@property (nonatomic) BOOL deviceBeginGeneratingOrientationNotificationsChangedByMine;
@end
