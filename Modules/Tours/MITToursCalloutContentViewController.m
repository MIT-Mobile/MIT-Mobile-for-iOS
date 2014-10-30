#import "MITToursCalloutContentViewController.h"
#import "UIFont+MITTours.h"
#import "UIKit+MITAdditions.h"

#define SMOOTS_PER_MILE 945.671642

@interface MITToursCalloutContentViewController ()

@property (weak, nonatomic) IBOutlet UILabel *stopTypeLabel;
@property (weak, nonatomic) IBOutlet UILabel *stopNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UIButton *detailButton;

@end

@implementation MITToursCalloutContentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // For now we will assume that the provided stopType is a user-facing string,
    // but to be more robust we might consider using an enum value and having the
    // view generate its own text.
    self.stopTypeLabel.text = [self.stopType uppercaseString];
    self.stopTypeLabel.font = [UIFont toursMapCalloutSubtitle];
    self.stopTypeLabel.textColor = [UIColor mit_greyTextColor];
    self.stopTypeLabel.preferredMaxLayoutWidth = [self maxLabelWidth];
    
    self.stopNameLabel.text = self.stopName;
    self.stopNameLabel.font = [UIFont toursMapCalloutTitle];
    self.stopNameLabel.preferredMaxLayoutWidth = [self maxLabelWidth];
    
    if (self.shouldDisplayDistance) {
        CGFloat smoots = self.distanceInMiles * SMOOTS_PER_MILE;
        self.distanceLabel.text = [NSString stringWithFormat:@"%.01f miles (%.f smoots)", self.distanceInMiles, smoots];
    } else {
        self.distanceLabel.text = @"";
    }
    self.distanceLabel.font = [UIFont toursMapCalloutSubtitle];
    self.distanceLabel.textColor = [UIColor mit_greyTextColor];
    self.distanceLabel.preferredMaxLayoutWidth = [self maxLabelWidth];
    
    [self.detailButton setImage:[UIImage imageNamed:@"map/map_disclosure_arrow"] forState:UIControlStateNormal];
}

- (IBAction)detailButtonWasPressed:(UIButton *)sender
{
    NSLog(@"Stop detail button pressed!");
}

- (CGSize)preferredContentSize
{
    return [self.view systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
}

- (CGFloat)maxLabelWidth
{
    return 200;
}

@end
