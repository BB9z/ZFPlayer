//
//  ZFPlayerLoadedRangeProgressView.h
//  Test
//
//  Created by BB9z on 8/2/16.
//
//

#import "RFUI.h"

@class AVPlayerItem;

@interface ZFPlayerLoadedRangeProgressView : UIView <
    RFInitializing
>

@property (nonatomic, strong) AVPlayerItem *item;

@end
