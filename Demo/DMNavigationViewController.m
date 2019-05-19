
#import "DMNavigationViewController.h"
#import <RFKit/UIViewController+RFInterfaceOrientation.h>
#import <objc/runtime.h>

@interface DMNavigationViewController () <UINavigationControllerDelegate>
@end

@implementation DMNavigationViewController
RFUIInterfaceOrientationSupportNavigation

- (void)awakeFromNib {
    [super awakeFromNib];
    self.delegate = self;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (navigationController != self) return;
    
    [self _updateNavigationAppearanceWithViewController:(id)viewController animated:animated];
    [self.transitionCoordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (context.isCancelled) {
            [self updateCurrentNavigationAppearanceAnimated:context.isAnimated];
        }
    }];
}

- (void)updateCurrentNavigationAppearanceAnimated:(BOOL)animated {
    [self _updateNavigationAppearanceWithViewController:(id)self.topViewController animated:animated];
}

- (void)_updateNavigationAppearanceWithViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    BOOL barHide = viewController.prefersNavigationBarHidden;
    if (barHide != self.navigationBarHidden) {
        [self setNavigationBarHidden:barHide animated:animated];
    }
}

@end


@implementation UIViewController (NavigationAppearance)

static char navigationBarHidden;
- (BOOL)prefersNavigationBarHidden {
    return [objc_getAssociatedObject(self, &navigationBarHidden) boolValue];
}
- (void)setPrefersNavigationBarHidden:(BOOL)prefersNavigationBarHidden {
    objc_setAssociatedObject(self, &navigationBarHidden, @(prefersNavigationBarHidden), OBJC_ASSOCIATION_ASSIGN);
}

@end
