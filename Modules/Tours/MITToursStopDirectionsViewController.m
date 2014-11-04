#import "MITToursStopDirectionsViewController.h"
#import "MITToursStop.h"

@interface MITToursStopDirectionsViewController ()

@end

@implementation MITToursStopDirectionsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = self.stop.title;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:YES];
}

@end
