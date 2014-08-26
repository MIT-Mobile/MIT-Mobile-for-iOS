#import "MITDiningHallMealCollectionCell.h"
#import "MITDiningMenuItem.h"
#import "DiningDietaryFlag.h"
#import "Foundation+MITAdditions.h"
#import "UIImage+PDF.h"

@interface MITDiningHallMealCollectionCell ()

@property (nonatomic, weak) IBOutlet UILabel *stationLabel;
@property (nonatomic, weak) IBOutlet UILabel *mealTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *mealDescriptionLabel;

@end

@implementation MITDiningHallMealCollectionCell

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
    self.stationLabel.preferredMaxLayoutWidth = self.bounds.size.width;
    self.mealTitleLabel.preferredMaxLayoutWidth = self.bounds.size.width;
    self.mealDescriptionLabel.preferredMaxLayoutWidth = self.bounds.size.width;
}

#pragma mark - Public Methods

- (void)setMenuItem:(MITDiningMenuItem *)menuItem
{
    self.stationLabel.text = menuItem.station;
    self.mealDescriptionLabel.text = menuItem.itemDescription;
    
    NSMutableAttributedString *mealNameLabelString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ", menuItem.name]];
    
    for (NSString *dietaryFlag in menuItem.dietaryFlags) {
        UIImage *dietaryFlagImage = [UIImage imageWithPDFNamed:[MITDiningMenuItem pdfNameForDietaryFlag:dietaryFlag] atSize:CGSizeMake(14, 14)];
        NSTextAttachment *dietaryFlagAttachment = [[NSTextAttachment alloc] init];
        dietaryFlagAttachment.image = dietaryFlagImage;
        
        NSAttributedString *imageString = [NSAttributedString attributedStringWithAttachment:dietaryFlagAttachment];
        [mealNameLabelString appendAttributedString:imageString];
    }
    
    self.mealTitleLabel.attributedText = mealNameLabelString;
}

#pragma mark - Determining Dynamic Cell Height

+ (CGFloat)heightForMenuItem:(MITDiningMenuItem *)menuItem width:(CGFloat)width
{
    MITDiningHallMealCollectionCell *sizingCell = [MITDiningHallMealCollectionCell sizingCell];
    [sizingCell setMenuItem:menuItem];
    return [MITDiningHallMealCollectionCell heightForCell:sizingCell width:width];
}

+ (CGFloat)heightForCell:(MITDiningHallMealCollectionCell *)cell width:(CGFloat)width
{
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    
    CGRect frame = cell.frame;
    frame.size.width = width;
    cell.frame = frame;
    
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    CGFloat height = [cell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    return MAX(44, height);
}

+ (MITDiningHallMealCollectionCell *)sizingCell
{
    static MITDiningHallMealCollectionCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UINib *numberedResultCellNib = [UINib nibWithNibName:NSStringFromClass([MITDiningHallMealCollectionCell class]) bundle:nil];
        sizingCell = [numberedResultCellNib instantiateWithOwner:nil options:nil][0];
    });
    return sizingCell;
}

@end
