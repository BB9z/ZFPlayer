
#import "ZFPlayerLoadedRangeProgressView.h"
#import "RFKVOWrapper.h"
@import AVFoundation;

@interface ZFPlayerLoadedRangeProgressView ()
@property (nonatomic, strong) id loadedTimeRangesObserver;
@property (nonatomic) BOOL loadedTimeRangesObservingEnable;
@end

@implementation ZFPlayerLoadedRangeProgressView
RFInitializingRootForUIView

- (void)onInit {
    // Initialization code
}

- (void)afterInit {
    // For overwrite
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    self.loadedTimeRangesObservingEnable = newWindow;
}

- (CGSize)sizeThatFits:(CGSize)size {
    size.height = 2;
    return size;
}

- (CGSize)intrinsicContentSize {
    return (CGSize){UIViewNoIntrinsicMetric, 2};
}

- (void)setItem:(AVPlayerItem *)item {
    if (_item == item) return;
    if (_item) {
        self.loadedTimeRangesObservingEnable = NO;
    }
    _item = item;
    if (item) {
        self.loadedTimeRangesObservingEnable = YES;
    }
    [self setNeedsDisplay];
}

- (void)setLoadedTimeRangesObservingEnable:(BOOL)loadedTimeRangesObservingEnable {
    if (_loadedTimeRangesObservingEnable == loadedTimeRangesObservingEnable) return;
    if (_loadedTimeRangesObservingEnable) {
        if (self.loadedTimeRangesObserver) {
            [self.item RFRemoveObserverWithIdentifier:self.loadedTimeRangesObserver];
            self.loadedTimeRangesObserver = nil;
        }
    }
    _loadedTimeRangesObservingEnable = loadedTimeRangesObservingEnable;
    if (loadedTimeRangesObservingEnable) {
        @weakify(self);
        self.loadedTimeRangesObserver = [self.item RFAddObserver:self forKeyPath:@keypath(self.item, loadedTimeRanges) options:NSKeyValueObservingOptionNew queue:[NSOperationQueue mainQueue] block:^(id observer, NSDictionary *change) {
            @strongify(self);
            [self setNeedsDisplay];
        }];
    }
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    UIColor *drawColor = self.tintColor;
    [drawColor setFill];

    CGRect frame = self.bounds;
    CGFloat width = CGRectGetWidth(frame);
    if (!(width > 0)) return;

    AVPlayerItem *item = self.item;
    double total = CMTimeGetSeconds(item.duration);
    if (total <= 0) return;

    for (NSValue *rangObject in item.loadedTimeRanges) {
        _douto(rangObject)
        CMTimeRange rang = [rangObject CMTimeRangeValue];
        double start = CMTimeGetSeconds(rang.start);
        double duration = CMTimeGetSeconds(rang.duration);

        frame.origin.x = width * start/total;
        frame.size.width = width * duration/total;

        UIBezierPath *blockPath = [UIBezierPath bezierPathWithRect:frame];
        [blockPath fill];
    }
}

@end
