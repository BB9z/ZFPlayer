
#import "RFUI.h"

float RFUIDebugSlowAnimationsRatio = 10;

bool RFEdgeEqualToEdge(RFEdge a, RFEdge b) {
	if (a.top == b.top && a.right == b.right &&
		a.bottom == b.bottom && a.left == b.left) {
		return true;
	}
	return false;
}

RFEdge RFEdgeMake(float top, float right, float bottom, float left) {
	RFEdge tmp;
	tmp.top = top;
	tmp.right = right;
	tmp.bottom = bottom;
	tmp.left = left;
	return tmp;
}

RFEdge RFEdgeMakeWithRects(CGRect outterRect, CGRect innerRect) {
	RFEdge tmp;
	tmp.top = CGRectGetMinY(innerRect) - CGRectGetMinY(outterRect);
	tmp.right = CGRectGetMaxX(outterRect) - CGRectGetMaxX(innerRect);
	tmp.bottom = CGRectGetMaxY(outterRect) - CGRectGetMaxY(innerRect);
	tmp.left = CGRectGetMinX(innerRect) - CGRectGetMinX(outterRect);
	return tmp;
}

const RFEdge    RFEdgeZero = {0,0,0,0};

#pragma mark - UIViewAutoresizing
NSUInteger const UIViewAutoresizingFlexibleSize = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
NSUInteger const UIViewAutoresizingFlexibleMargin = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
