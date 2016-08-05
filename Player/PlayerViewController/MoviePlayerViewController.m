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
#import "ZFPlayerView.h"

@interface UIDevice (/* Fake */)
- (void)setOrientation:(UIDeviceOrientation)orientation animated:(BOOL)animated;
@end

@interface MoviePlayerViewController ()
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

    self.playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.playerView.translatesAutoresizingMaskIntoConstraints = YES;
    [self.playerView bringToFront];

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
    self.playerView.videoURL = [NSURL URLWithString:@"http://baobab.wdjcdn.com/1456480115661mtl.mp4"];
}

- (IBAction)onV3:(id)sender {
    self.playerView.videoURL = [NSURL URLWithString:@"http://baobab.wdjcdn.com/1456665467509qingshu.mp4"];
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
            [[UIDevice currentDevice] setOrientation:UIDeviceOrientationLandscapeLeft animated:YES];
        }
    }
    else {
        if (self.lockFullscreen) {
            self.lockFullscreen = NO;
            [[UIDevice currentDevice] setOrientation:UIDeviceOrientationPortrait animated:YES];
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

@end
