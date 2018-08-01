/*!
 ZFPlayerLoadedRangeProgressView
 
 Copyright © 2016, 2018 BB9z.
 https://github.com/BB9z/ZFPlayer
 
 The MIT License (MIT)
 http://www.opensource.org/licenses/mit-license.php
 */
#import <RFKit/RFRuntime.h>
#import <RFInitializing/RFInitializing.h>

@class AVPlayerItem;

@interface ZFPlayerLoadedRangeProgressView : UIView <
    RFInitializing
>

@property (nonatomic, strong) AVPlayerItem *item;

@end
