/*!
 DMNavigationViewController
 ZFPlayer Demo
 
 Created by BB9z on 8/2/16.
 */
#import <UIKit/UIKit.h>

@interface DMNavigationViewController : UINavigationController

- (void)updateCurrentNavigationAppearanceAnimated:(BOOL)animated;
@end

@interface UIViewController (NavigationAppearance)

///
@property IBInspectable BOOL prefersNavigationBarHidden;
@end
