#import "MITToursHomeViewController.h"
#import "MITToursWebservices.h"

@interface MITToursHomeViewController ()

@end

@implementation MITToursHomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [MITToursWebservices getToursWithCompletion:^(id object, NSError *error) {
        MITToursTour *tour = object[0];
        [MITToursWebservices getTourDetailForTour:tour completion:^(id object, NSError *error) {
            
        }];
    }];
}

@end
