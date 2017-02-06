#import "MITDiningVenueInfoCell.h"
#import "MITDiningHouseVenue.h"
#import "MITDiningHouseDay.h"
#import "MITDiningRetailVenue.h"
#import "MITDiningRetailDay.h"
#import "UIKit+MITAdditions.h"

static CGFloat kMITDiningVenueCellEstimatedHeight = 67.0;

@interface MITDiningVenueInfoCell ()

@property (weak, nonatomic) IBOutlet UILabel *venueNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *venueHoursLabel;

@property (weak, nonatomic) IBOutlet UIImageView *venueIconImageView;


@end

@implementation MITDiningVenueInfoCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self refreshLabelLayoutWidths];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.venueHoursLabel.textColor = [UIColor mit_greyTextColor];
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
    MITDiningHouseDay *diningDay = [venue houseDayForDate:[NSDate date]];
    self.venueHoursLabel.text = [diningDay statusStringForDate:[NSDate date]];

    [self setVenue:venue];
}

- (void)setRetailVenue:(MITDiningRetailVenue *)venue
{
    MITDiningRetailDay *retailDay = [venue retailDayForDate:[NSDate date]];
    self.venueHoursLabel.text = [retailDay statusStringForDate:[NSDate date]];
    
    self.infoButton.hidden = YES;
    [self setVenue:venue];
}

- (void)setVenue:(id)venue
{
    [self.venueIconImageView setImageWithURL:[NSURL URLWithString:[venue iconURL]]];
    
    self.venueNameLabel.text = [venue name];
    
    self.venueHoursLabel.textColor = [venue isOpenNow] ? [UIColor mit_openGreenColor] : [UIColor mit_closedRedColor];
    
    [self layoutIfNeeded];
}

#pragma mark - Cell Sizing

+ (CGFloat)heightForHouseVenue:(MITDiningHouseVenue *)venue
                tableViewWidth:(CGFloat)width
{
    [[MITDiningVenueInfoCell sizingCell] setHouseVenue:venue];
    return [MITDiningVenueInfoCell heightForCell:[MITDiningVenueInfoCell sizingCell] TableWidth:width];
}

+ (CGFloat)heightForRetailVenue:(MITDiningRetailVenue *)venue tableViewWidth:(CGFloat)width
{
    [[MITDiningVenueInfoCell sizingCell] setRetailVenue:venue];
    return [MITDiningVenueInfoCell heightForCell:[MITDiningVenueInfoCell sizingCell] TableWidth:width];
}

+ (CGFloat)heightForCell:(MITDiningVenueInfoCell *)cell TableWidth:(CGFloat)width
{
    CGRect frame = cell.frame;
    frame.size.width = width;
    cell.frame = frame;
    
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    ++height; // add pixel for cell separator
    return MAX(kMITDiningVenueCellEstimatedHeight, height);
}

+ (MITDiningVenueInfoCell *)sizingCell
{
    static MITDiningVenueInfoCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UINib *numberedResultCellNib = [UINib nibWithNibName:NSStringFromClass([MITDiningVenueInfoCell class]) bundle:nil];
        sizingCell = [numberedResultCellNib instantiateWithOwner:nil options:nil][0];
    });
    return sizingCell;
}

- (IBAction)infoButtonPressed:(id)sender
{
    [self.delegate infoCellDidPressInfoButton:self];
}

@end

