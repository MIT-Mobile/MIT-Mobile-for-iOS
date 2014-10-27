#import "MITToursSelfGuidedTourCell.h"
#import "MITToursTour.h"

@interface MITToursSelfGuidedTourCell ()

@property (weak, nonatomic) IBOutlet UILabel *tourTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *tourShortDescriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *tourDistanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *tourDurationLabel;

@end

@implementation MITToursSelfGuidedTourCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.separatorInset = UIEdgeInsetsMake(0, self.frame.size.width, 0, 0);
}

- (void)setTour:(MITToursTour *)tour
{
    self.tourTitleLabel.text = tour.title;
    self.tourShortDescriptionLabel.text = tour.shortTourDescription;
    self.tourDistanceLabel.text = tour.localizedLengthString;
    self.tourDurationLabel.text = tour.durationString;
}

@end
