#import "MITDiningHouseVenueInfoCell.h"
#import "MITDiningHouseVenue.h"
#import "MITDiningHouseDay.h"
#import "UIKit+MITAdditions.h"

static CGFloat kMITDiningVenueCellEstimatedHeight = 67.0;

@interface MITDiningHouseVenueInfoCell ()

@property (weak, nonatomic) IBOutlet UILabel *venueNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *venueHoursLabel;

@property (weak, nonatomic) IBOutlet UIImageView *venueIconImageView;


@end

@implementation MITDiningHouseVenueInfoCell

- (void)awakeFromNib
{
    [self refreshLabelLayoutWidths];
    
    self.venueHoursLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self layoutIfNeeded];
    [self refreshLabelLayoutWidths];
}

- (void)refreshLabelLayoutWidths
{
    self.venueNameLabel.preferredMaxLayoutWidth = self.venueNameLabel.frame.size.width;
    self.venueHoursLabel.preferredMaxLayoutWidth = self.venueHoursLabel.frame.size.width;
}

#pragma mark - Venue Setup

- (void)setHouseVenue:(MITDiningHouseVenue *)venue
{
    [self.venueIconImageView setImageWithURL:[NSURL URLWithString:venue.iconURL]];
    
    self.venueNameLabel.text = venue.name;
    self.venueHoursLabel.text = [venue hoursToday];
    
    MITDiningHouseDay *diningDay = [venue houseDayForDate:[NSDate date]];
    self.venueHoursLabel.text = [diningDay statusStringForDate:[NSDate date]];

    self.venueHoursLabel.textColor = venue.isOpenNow ? [UIColor mit_openGreenColor] : [UIColor mit_closedRedColor];
    
    [self layoutIfNeeded];
}

#pragma mark - Cell Sizing

+ (CGFloat)heightForHouseVenue:(MITDiningHouseVenue *)venue
                tableViewWidth:(CGFloat)width
{
    [[MITDiningHouseVenueInfoCell sizingCell] setHouseVenue:venue];
    return [MITDiningHouseVenueInfoCell heightForCell:[MITDiningHouseVenueInfoCell sizingCell] TableWidth:width];
}


+ (CGFloat)heightForCell:(MITDiningHouseVenueInfoCell *)cell TableWidth:(CGFloat)width
{
    CGRect frame = cell.frame;
    frame.size.width = width;
    cell.frame = frame;
    
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    ++height; // add pixel for cell separator
    return MAX(kMITDiningVenueCellEstimatedHeight, height);
}

+ (MITDiningHouseVenueInfoCell *)sizingCell
{
    static MITDiningHouseVenueInfoCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UINib *numberedResultCellNib = [UINib nibWithNibName:NSStringFromClass([MITDiningHouseVenueInfoCell class]) bundle:nil];
        sizingCell = [numberedResultCellNib instantiateWithOwner:nil options:nil][0];
    });
    return sizingCell;
}

- (IBAction)infoButtonPressed:(id)sender
{
    [self.delegate infoCellDidPressInfoButton:self];
}



@end

