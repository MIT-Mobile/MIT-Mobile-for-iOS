#import "MITToursHomeViewController.h"
#import "MITToursWebservices.h"

@interface MITToursHomeViewController ()

@end

@implementation MITToursHomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [MITToursWebservices getToursWithCompletion:^(NSArray *tours, NSError *error) {
        
    }];
    
}

@end
