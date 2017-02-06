#import "MITDiningHallMealCollectionHeader.h"
#import "MITDiningHouseVenue.h"
#import "MITDiningHouseDay.h"
#import "MITDiningMeal.h"
#import "UIKit+MITAdditions.h"

@interface MITDiningHallMealCollectionHeader ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *venueNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *currentMealHoursLabel;
@property (nonatomic, weak) IBOutlet UILabel *currentStatusLabel;
@property (nonatomic, weak) IBOutlet UIButton *infoButton;
@property (nonatomic, strong) MITDiningHouseVenue *venue;


- (IBAction)infoButtonPressed:(id)sender;

@end

@implementation MITDiningHallMealCollectionHeader

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.currentStatusLabel.preferredMaxLayoutWidth = self.currentStatusLabel.bounds.size.width;
}

- (IBAction)infoButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(diningHallHeaderInfoButtonPressedForHouse:)]) {
        [self.delegate diningHallHeaderInfoButtonPressedForHouse:self.venue];
    }
}

#pragma mark - Public Methods

- (void)setDiningHouseVenue:(MITDiningHouseVenue *)venue day:(MITDiningHouseDay *)day mealName:(NSString *)mealName
{
    self.venue = venue;
    
    self.imageView.image = nil;
    [self.imageView setImageWithURL:[NSURL URLWithString:venue.iconURL]];
    
    NSString *mealHoursString = @"";
    if ([day mealWithName:mealName]) {
        mealHoursString = [[day mealWithName:mealName] mealHoursDescription];
    }
    self.currentMealHoursLabel.text = [NSString stringWithFormat:@"%@ %@", mealName, mealHoursString];
    
    self.currentStatusLabel.text = [day statusStringForDate:[NSDate date]];
    if ([venue isOpenNow]) {
        self.currentStatusLabel.textColor = [UIColor mit_openGreenColor];
    } else {
        self.currentStatusLabel.textColor = [UIColor mit_closedRedColor];
    }
    
    CGFloat remainingWidth = self.bounds.size.width;
    remainingWidth -= self.imageView.frame.origin.x + self.imageView.frame.size.width;
    remainingWidth -= 10; // padding from icon to name label
    
    remainingWidth -= self.infoButton.frame.size.width;
    
    remainingWidth -= self.currentStatusLabel.frame.size.width;
    remainingWidth -= 8; // padding from status to info button
    
    NSDictionary *hoursTextAttributes = @{NSFontAttributeName: self.currentMealHoursLabel.font};
    CGSize hoursSize = [self.currentMealHoursLabel.text sizeWithAttributes:hoursTextAttributes];
    remainingWidth -= hoursSize.width;
    remainingWidth -= 8; // padding from hours to status
    
    remainingWidth -= 6; // padding from namel label to hours
    
    self.venueNameLabel.preferredMaxLayoutWidth = remainingWidth;
    self.venueNameLabel.text = venue.name;
}

#pragma mark - Determining Dynamic Header Height

+ (CGFloat)heightForDiningHouseVenue:(MITDiningHouseVenue *)venue day:(MITDiningHouseDay *)day mealName:(NSString *)mealName collectionViewWidth:(CGFloat)collectionViewWidth
{
    MITDiningHallMealCollectionHeader *sizingHeader = [MITDiningHallMealCollectionHeader sizingHeader];
    [sizingHeader setDiningHouseVenue:venue day:day mealName:mealName];
    return [MITDiningHallMealCollectionHeader heightForHeader:sizingHeader collectionViewWidth:collectionViewWidth];
}

+ (CGFloat)heightForHeader:(MITDiningHallMealCollectionHeader *)header collectionViewWidth:(CGFloat)width
{
    CGRect frame = header.frame;
    frame.size.width = width;
    header.frame = frame;
    
    CGFloat height = [header systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    return MAX(48, height);
}

+ (MITDiningHallMealCollectionHeader *)sizingHeader
{
    static MITDiningHallMealCollectionHeader *sizingHeader;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UINib *numberedResultCellNib = [UINib nibWithNibName:NSStringFromClass([MITDiningHallMealCollectionHeader class]) bundle:nil];
        sizingHeader = [numberedResultCellNib instantiateWithOwner:nil options:nil][0];
    });
    return sizingHeader;
}

@end
