
#import "DMMainViewController.h"
#import "DMNavigationViewController.h"
#import "MoviePlayerViewController.h"

@interface DMMainViewController ()

@end

@implementation DMMainViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    MoviePlayerViewController *movie = (MoviePlayerViewController *)segue.destinationViewController;
    if ([segue.identifier isEqualToString:@"S1"]) {
        NSURL *videoURL = [[NSBundle mainBundle] URLForResource:@"150511_JiveBike" withExtension:@"mov"];
        movie.videoURL = videoURL;
        movie.autoPlay = YES;
        movie.prefersNavigationBarHidden = YES;
    }
    else if ([segue.identifier isEqualToString:@"S2"]) {

    }
}

@end
