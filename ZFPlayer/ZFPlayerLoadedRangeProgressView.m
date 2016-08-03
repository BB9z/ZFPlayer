
#import "ZFPlayerLoadedRangeProgressView.h"
@import AVFoundation;

@interface ZFPlayerLoadedRangeProgressView ()
@end

@implementation ZFPlayerLoadedRangeProgressView
RFInitializingRootForUIView

- (void)onInit {
    // Initialization code
}

- (void)afterInit {

}

- (CGSize)sizeThatFits:(CGSize)size {
    size.height = 2;
    return size;
}

- (CGSize)intrinsicContentSize {
    return (CGSize){UIViewNoIntrinsicMetric, 2};
}

- (void)setItem:(AVPlayerItem *)item {
    _item = item;
    [self setNeedsDisplay];
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
