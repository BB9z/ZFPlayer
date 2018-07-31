//
//  MoviePlayerViewController.m
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

#import "MoviePlayerViewController.h"
#import "ZFPlayerControlView.h"
#import <RFKit/UIView+RFKit.h>


@interface MoviePlayerViewController () <
    ZFPlayerDisplayDelegate
>
@property (nonatomic) BOOL hasApplyFullscreenLayout;
@end

@implementation MoviePlayerViewController

- (BOOL)prefersStatusBarHidden {
    return self.playerView.shouldApplyFullscreenLayout;
}

- (void)dealloc {
    NSLog(@"%@释放了", self.class);
}

- (void)viewDidLoad {
    [super viewDidLoad];

    ZFPlayerView *pv = self.playerView;
    pv.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    pv.translatesAutoresizingMaskIntoConstraints = YES;
    pv.playbackInfoUpdateInterval = 4;
    [pv addDisplayer:self];
    [pv bringToFront];

    ZFPlayerControlView *cv = [ZFPlayerControlView loadWithNibName:nil];
    cv.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    cv.frame = pv.bounds;
    cv.player = pv;
    [pv addSubview:cv];

    if (self.autoPlay) {
        self.playerView.videoURL = self.videoURL;
    }
}

- (IBAction)onBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onV1:(id)sender {
    NSURL *videoURL = [[NSBundle mainBundle] URLForResource:@"150511_JiveBike" withExtension:@"mov"];
    self.playerView.videoURL = videoURL;
}

- (IBAction)onV2:(id)sender {
    self.playerView.videoURL = [NSURL URLWithString:@"https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8"];
}

- (IBAction)onV3:(id)sender {
    self.playerView.videoURL = [NSURL URLWithString:@"https://static.smartisanos.cn/common/video/proud-farmer.mp4"];
}

- (IBAction)onStop:(id)sender {
    [self.playerView stop];
}

#pragma mark - 屏幕旋转，全屏

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (self.lockFullscreen) {
        return UIInterfaceOrientationMaskLandscape;
    }
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)setOrientation:(UIDeviceOrientation)orientation {
    [[UIDevice currentDevice] setValue:@(orientation) forKey:@"orientation"];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if (self.playerView.shouldApplyFullscreenLayout) {
        self.playerView.frame = self.view.bounds;
        self.hasApplyFullscreenLayout = YES;
    }
    else {
        CGRect frame = self.view.bounds;
        frame.origin.y = self.topLayoutGuide.length;
        frame.size.height = frame.size.width/16*9;
        self.playerView.frame = frame;
        self.hasApplyFullscreenLayout = NO;
    }
}

- (IBAction)onEnterFullscreenMode:(UIButton *)sender {
    BOOL shouldEnterFullscreen = !self.playerView.shouldApplyFullscreenLayout;
    if (shouldEnterFullscreen) {
        if (!self.lockFullscreen) {
            self.lockFullscreen = YES;
            // 仍然不知道如何才能避免这个私有方法的调用
            // 调用 attemptRotationToDeviceOrientation 并没有重新要 supportedInterfaceOrientations 并更新
            [self setOrientation:UIDeviceOrientationLandscapeLeft];
        }
    }
    else {
        if (self.lockFullscreen) {
            self.lockFullscreen = NO;
            [self setOrientation:UIDeviceOrientationPortrait];
        }
    }
    [self.class attemptRotationToDeviceOrientation];
}

- (void)setHasApplyFullscreenLayout:(BOOL)hasApplyFullscreenLayout {
    if (_hasApplyFullscreenLayout == hasApplyFullscreenLayout) return;
    _hasApplyFullscreenLayout = hasApplyFullscreenLayout;

    [self setNeedsStatusBarAppearanceUpdate];
    [self.navigationController setNavigationBarHidden:hasApplyFullscreenLayout animated:YES];
}

#pragma mark - 错误

// 这里演示简单的错误处理。
// 一般来说，根据具体情况做相应处理放在 vc 逻辑里比较合适；
// 如果有一致的 UI 逻辑，也可以写在 control view 里。

- (void)ZFPlayer:(ZFPlayerView *)player didReciveError:(NSError *)error {
    self.errorLabel.text = error.localizedDescription;
}

@end
