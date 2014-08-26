#import "MITDiningVenueCell.h"
#import "MITDiningHouseVenue.h"
#import "MITDiningRetailVenue.h"

static CGFloat kMITDiningVenueCellEstimatedHeight = 67.0;

@interface MITDiningVenueCell ()

@property (weak, nonatomic) IBOutlet UILabel *venueNameLabel;

@property (weak, nonatomic) IBOutlet UILabel *venueHoursLabel;
@property (weak, nonatomic) IBOutlet UILabel *venueStatusLabel;

@property (weak, nonatomic) IBOutlet UIImageView *venueIconImageView;

@end

@implementation MITDiningVenueCell

- (void)awakeFromNib
{
    [self refreshLabelLayoutWidths];
   
    self.venueHoursLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    self.separatorInset = UIEdgeInsetsMake(0, 76, 0, 0);
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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
    self.venueStatusLabel.preferredMaxLayoutWidth = self.venueStatusLabel.frame.size.width;
}

#pragma mark - Venue Setup

// HouseVenue and RetailVenue aren't subclassed for CoreData reasons, but they
// share the same methods we need here, so we'll just accept type id, which is
/// either a house or a retail object.
- (void)setVenue:(id)venue withNumberPrefix:(NSString *)numberPrefix
{
    [self.venueIconImageView setImageWithURL:[NSURL URLWithString:[venue iconURL]]];
    
    NSString *nameLabelText = [venue name];
    if (numberPrefix) {
        nameLabelText = [NSString stringWithFormat:@"%@. %@", numberPrefix, nameLabelText];
    }
    self.venueNameLabel.text = nameLabelText;
    self.venueHoursLabel.text = [venue hoursToday];
    
    if ([venue isOpenNow]) {
        self.venueStatusLabel.text = @"Open";
        self.venueStatusLabel.textColor = [UIColor colorWithRed:23.0/255.0 green:137.0/255.0 blue:27.0/255.0 alpha:1.0];
    }
    else {
        self.venueStatusLabel.text = @"Closed";
        self.venueStatusLabel.textColor = [UIColor colorWithRed:179.0/255.0 green:29.0/255.0 blue:16.0/255.0 alpha:1.0];
    }
    
    [self layoutIfNeeded];
}

#pragma mark - Cell Sizing

+ (CGFloat)heightForHouseVenue:(MITDiningHouseVenue *)venue
           tableViewWidth:(CGFloat)width
{
    [[MITDiningVenueCell sizingCell] setVenue:venue withNumberPrefix:@""];
    return [MITDiningVenueCell heightForCell:[MITDiningVenueCell sizingCell] TableWidth:width];
}

+ (CGFloat)heightForRetailVenue:(MITDiningRetailVenue *)venue
              withNumberPrefix:(NSString *)numberPrefix
                tableViewWidth:(CGFloat)width
{
    [[MITDiningVenueCell sizingCell] setVenue:venue withNumberPrefix:numberPrefix];
    return [MITDiningVenueCell heightForCell:[MITDiningVenueCell sizingCell] TableWidth:width];
}

+ (CGFloat)heightForCell:(MITDiningVenueCell *)cell TableWidth:(CGFloat)width
{
    CGRect frame = cell.frame;
    frame.size.width = width;
    cell.frame = frame;
    
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    ++height; // add pixel for cell separator
    return MAX(kMITDiningVenueCellEstimatedHeight, height);
}

+ (MITDiningVenueCell *)sizingCell
{
    static MITDiningVenueCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UINib *numberedResultCellNib = [UINib nibWithNibName:NSStringFromClass([MITDiningVenueCell class]) bundle:nil];
        sizingCell = [numberedResultCellNib instantiateWithOwner:nil options:nil][0];
    });
    return sizingCell;
}

@end
