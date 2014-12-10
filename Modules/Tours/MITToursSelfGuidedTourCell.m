#import "MITToursSelfGuidedTourCell.h"
#import "MITToursTour.h"

@interface MITToursSelfGuidedTourCell ()

@property (weak, nonatomic) IBOutlet UILabel *tourTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *tourShortDescriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *tourDistanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *tourDurationLabel;
@property (weak, nonatomic) IBOutlet UIView *tourView;
@property (weak, nonatomic) IBOutlet UIImageView *toursImageView;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;
@property (weak, nonatomic) IBOutlet UIView *highlightView;

@end

@implementation MITToursSelfGuidedTourCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.separatorInset = UIEdgeInsetsMake(0, self.frame.size.width, 0, 0);
    self.toursImageView.image = [UIImage imageNamed:@"tours/tours_cover_image.jpg"];
    self.tourView.hidden = YES;
    self.highlightView.hidden = YES;
    
    self.contentView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
}

- (void)setTour:(MITToursTour *)tour
{
    self.tourTitleLabel.text = tour.title;
    self.tourShortDescriptionLabel.text = tour.shortTourDescription;
    self.tourDistanceLabel.text = tour.localizedLengthString;
    self.tourDurationLabel.text = tour.durationString;
    
    self.tourView.hidden = NO;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    self.highlightView.hidden = !highlighted;
}

@end
