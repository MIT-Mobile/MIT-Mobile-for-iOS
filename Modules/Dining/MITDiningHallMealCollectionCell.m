#import "MITDiningHallMealCollectionCell.h"
#import "MITDiningMenuItem.h"
#import "Foundation+MITAdditions.h"
#import "UIImage+PDF.h"
#import "MITDiningDietaryFlagListViewController.h"
#import "MITDiningTappableDietaryFlagLabel.h"

@interface MITDiningHallMealCollectionCell () <UITextViewDelegate, MITDiningTappableDietaryFlagLabelDelegate>

@property (nonatomic, weak) IBOutlet UILabel *stationLabel;
@property (nonatomic, weak) IBOutlet MITDiningTappableDietaryFlagLabel *mealTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *mealDescriptionLabel;
@property (nonatomic, strong) UIPopoverController *dietaryFlagPopoverController;

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
    self.mealDescriptionLabel.preferredMaxLayoutWidth = self.bounds.size.width;
    self.mealTitleLabel.preferredMaxLayoutWidth = self.bounds.size.width;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.mealTitleLabel.delegate = self;
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
}

- (void)fixHangingFlags
{
    if (![self.menuItem.dietaryFlags isKindOfClass:[NSArray class]]) {
        return;
    } else if (((NSArray *)self.menuItem.dietaryFlags).count < 1) {
        return;
    }
    
    NSMutableAttributedString *dietaryFlagString = [MITDiningMenuItem dietaryFlagsStringForFlags:self.menuItem.dietaryFlags atSize:CGSizeMake(20, 20) verticalAdjustment:-5];
    NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ", self.menuItem.name] attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:17]}];
    [titleString appendAttributedString:dietaryFlagString];
    
    NSMutableAttributedString *titleWithoutFlags = [[NSMutableAttributedString alloc] initWithAttributedString:titleString];
    __block BOOL foundFlag = NO;
    __block NSUInteger locationOfFirstFlag = 0;
    [titleWithoutFlags enumerateAttributesInRange:NSMakeRange(0, titleWithoutFlags.length) options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        if ([attrs objectForKey:NSAttachmentAttributeName]) {
            if (!foundFlag) {
                foundFlag = YES;
                locationOfFirstFlag = range.location;
            }
        }
    }];
    
    if (foundFlag) {
        [titleWithoutFlags deleteCharactersInRange:NSMakeRange(locationOfFirstFlag, titleWithoutFlags.length - locationOfFirstFlag)];
        CGRect fullStringRect = [titleString boundingRectWithSize:CGSizeMake(self.targetWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) context:nil];
        CGRect stringWithoutFlagsRect = [titleWithoutFlags boundingRectWithSize:CGSizeMake(self.targetWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) context:nil];
        
        // The dietary flag icons make the string slightly taller (~1pt). We want to know if the string is tall enough to warrant an extra line, so we add a little padding
        // Also need to check if the returned bounding box will render wider than the target width...for some reason the bounding box method seems to think this is ok sometimes
        if (ceil(fullStringRect.size.height) > (ceil(stringWithoutFlagsRect.size.height) + 5) || ceil(fullStringRect.size.width) > self.targetWidth) {
            // If the flags will push the string to a new line, find the space before last word and add a newline char before it
            NSRange rangeOfLastSpace = [[self.menuItem.name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] rangeOfString:@" " options:NSBackwardsSearch];
            [titleString replaceCharactersInRange:rangeOfLastSpace withString:@"\n"];
            self.mealTitleLabel.attributedText = [[NSAttributedString alloc] initWithAttributedString:titleString];
        }
    }
}

#pragma mark - Public Methods

- (void)setMenuItem:(MITDiningMenuItem *)menuItem
{
    if ([menuItem isEqual:_menuItem]) {
        return;
    }
    
    _menuItem = menuItem;
    
    if (menuItem.station.length > 0) {
        self.stationLabel.text = menuItem.station;
    } else {
        self.stationLabel.text = @"";
    }
    
    if (menuItem.itemDescription.length > 0) {
        self.mealDescriptionLabel.text = menuItem.itemDescription;
    } else {
        self.mealDescriptionLabel.text = @"";
    }

    if (menuItem.name.length > 0) {
        NSMutableAttributedString *dietaryFlagString = [MITDiningMenuItem dietaryFlagsStringForFlags:menuItem.dietaryFlags atSize:CGSizeMake(20, 20) verticalAdjustment:-5];
        NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ", menuItem.name] attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:17]}];
        [titleString appendAttributedString:dietaryFlagString];
        self.mealTitleLabel.attributedText = [[NSAttributedString alloc] initWithAttributedString:titleString];
    } else {
        self.mealTitleLabel.text = @"";
    }
}

- (void)setTargetWidth:(CGFloat)targetWidth
{
    _targetWidth = floor(targetWidth);
    [self fixHangingFlags];
}

#pragma mark - MITDiningTappableDietaryFlagLabelDelegate Methods

- (void)dietaryFlagTappedInLabel:(MITDiningTappableDietaryFlagLabel *)label withPopoverRect:(CGRect)popoverRect
{
    if (![self.menuItem.dietaryFlags isKindOfClass:[NSArray class]]) {
        return;
    } else if (((NSArray *)self.menuItem.dietaryFlags).count < 1) {
        return;
    }
    
    MITDiningDietaryFlagListViewController *flagsVC = [[MITDiningDietaryFlagListViewController alloc] init];
    flagsVC.flags = self.menuItem.dietaryFlags;
    self.dietaryFlagPopoverController = [[UIPopoverController alloc] initWithContentViewController:flagsVC];
    self.dietaryFlagPopoverController.popoverContentSize = [flagsVC targetTableViewSize];
    
    [self.dietaryFlagPopoverController presentPopoverFromRect:popoverRect inView:self.mealTitleLabel permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

#pragma mark - Determining Dynamic Cell Height

+ (CGFloat)heightForMenuItem:(MITDiningMenuItem *)menuItem width:(CGFloat)width
{
    MITDiningHallMealCollectionCell *sizingCell = [MITDiningHallMealCollectionCell sizingCell];
    [sizingCell setMenuItem:menuItem];
    sizingCell.targetWidth = width;
    return [MITDiningHallMealCollectionCell heightForCell:sizingCell width:width];
}

+ (CGFloat)heightForCell:(MITDiningHallMealCollectionCell *)cell width:(CGFloat)width
{
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    
    CGRect frame = cell.frame;
    frame.size.width = floor(width);
    cell.frame = frame;
    
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    CGFloat height = ceil([cell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height);
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
