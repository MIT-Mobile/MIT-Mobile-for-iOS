
#import "DiningHallMenuItemTableCell.h"
#import "UIKit+MITAdditions.h"
#import "UIImage+PDF.h"

#define TITLE_DESCRIPTION_PADDING 4
#define TYPE_ICON_SIZE 24

@interface DiningHallMenuItemTableCell()

@property (nonatomic, strong) UILabel * station;
@property (nonatomic, strong) UILabel * title;
@property (nonatomic, strong) UILabel * description;

@property (nonatomic, strong) UIView * typeContainer;

@end

@implementation DiningHallMenuItemTableCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
                                                                            // heights are initialized to be minimum allowed. Height will vary
        self.station        = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, 60, 14)];
        self.title          = [[UILabel alloc] initWithFrame:CGRectMake(90, 15, 160, 14)];
        self.description    = [[UILabel alloc] initWithFrame:CGRectMake(90, 41, 160, 12)];
        
        [self formatLabel:self.station withFont:[[self class] primaryFont]];
        [self formatLabel:self.title withFont:[[self class] primaryFont]];
        [self formatLabel:self.description withFont:[[self class] secondaryFont]];
        
        self.typeContainer  = [[UIView alloc] initWithFrame:CGRectMake(265, 15, (TYPE_ICON_SIZE * 2) + 5, TYPE_ICON_SIZE)];   // if more than 2 this view will need to resize
        
        [self.contentView addSubview:self.station];
        [self.contentView addSubview:self.title];
        [self.contentView addSubview:self.description];
        [self.contentView addSubview:self.typeContainer];
    }
    return self;
}

- (void) formatLabel:(UILabel *) label withFont:(UIFont *) font
{
    label.numberOfLines     = 0;
    label.lineBreakMode     = UILineBreakModeWordWrap;
    label.font              = font;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    [self adjustSizeForLabel:self.station];
    [self adjustSizeForLabel:self.title];
    [self adjustSizeForLabel:self.description];
    
    // sizes have beeen adjusted, need to layout origin
    // description origin should be the only dynamic origin
    CGRect frame = self.description.frame;
    frame.origin = CGPointMake(frame.origin.x, CGRectGetMaxY(self.title.frame) + TITLE_DESCRIPTION_PADDING);
    self.description.frame = frame;
    
    if ([self.dietaryTypes count] > 2) {
        self.typeContainer.frame = CGRectMake(265, 15, 45, 45);
    }
    [self layoutDietaryTypes];
    
}

- (void) layoutDietaryTypes
{
    CGSize iconSize = CGSizeMake(TYPE_ICON_SIZE, TYPE_ICON_SIZE);
    int maxIcons = 4;
    NSMutableArray *icons = [NSMutableArray arrayWithCapacity:maxIcons];
    for (NSNumber *type in self.dietaryTypes) {
        UIImage *image;
        if ([type intValue] == 1) {
            image = [UIImage imageWithPDFNamed:@"dining/farm_to_fork.pdf" fitSize:iconSize];
        } else if ([type intValue] == 2) {
            image = [UIImage imageWithPDFNamed:@"dining/gluten_free.pdf" fitSize:iconSize];
        } else if ([type intValue] == 3) {
            image = [UIImage imageWithPDFNamed:@"dining/halal.pdf" fitSize:iconSize];
        } else if ([type intValue] == 4) {
            image = [UIImage imageWithPDFNamed:@"dining/humane.pdf" fitSize:iconSize];
        }
        if (image != nil) {
            [icons addObject:image];
        }
    }
    
    for (int i = 0; i < [icons count]; i++) {
        UIImageView *iconView = [[UIImageView alloc] initWithImage:icons[i]];
        // there can only be a maximum of four icons, they are aligned like so :    1 0
        //                                                                          3 2
        // full layout description can be found in the spec: https://jira.mit.edu/jira/secure/attachment/26097/house+menu.pdf
        iconView.center = CGPointMake(35 - (iconSize.width + 5) * (i % 2), 10 + (iconSize.height + 5) * (i >= 2));
        [self.typeContainer addSubview:iconView];
    }
}

- (void) adjustSizeForLabel:(UILabel *)label
{
    CGSize maximumLabelSize = CGSizeMake(CGRectGetWidth(label.bounds), CGFLOAT_MAX);
    
    CGSize necessaryLabelSize = [[label text] sizeWithFont:label.font constrainedToSize:maximumLabelSize lineBreakMode:label.lineBreakMode];
    
    CGRect newFrame = label.frame;
    newFrame.size   = necessaryLabelSize;
    label.frame     = newFrame;
}


#pragma mark - Internal Class Helpers

+ (UIFont *) primaryFont
{
    return [UIFont fontWithName:@"Helvetica-Bold" size:14];
}

+ (UIFont *) secondaryFont
{
    return [UIFont fontWithName:@"Helvetica" size:12];
}

#pragma mark - Class Methods
+ (CGFloat) cellHeightForCellWithStation:(NSString *)station title:(NSString *) title description:(NSString *)description
{
    CGFloat stationWidth        = 60;
    CGFloat titleWidth          = 160;
    CGFloat descriptionWidth    = 160;
    
    CGSize maximumStationSize       = CGSizeMake(stationWidth, CGFLOAT_MAX);
    CGSize maximumTitleSize         = CGSizeMake(titleWidth, CGFLOAT_MAX);
    CGSize maximumDescriptionSize   = CGSizeMake(descriptionWidth, CGFLOAT_MAX);
    
    CGSize necessaryStationLabelSize        = [station sizeWithFont:[self primaryFont] constrainedToSize:maximumStationSize lineBreakMode:UILineBreakModeWordWrap];
    CGSize necessaryTitleLabelSize          = [title sizeWithFont:[self primaryFont] constrainedToSize:maximumTitleSize lineBreakMode:UILineBreakModeWordWrap];
    CGSize necessaryDescriptionLabelSize    = [description sizeWithFont:[self secondaryFont] constrainedToSize:maximumDescriptionSize lineBreakMode:UILineBreakModeWordWrap];
    
    CGFloat stationHeight   = 30 + necessaryStationLabelSize.height;
    CGFloat dataHeight      = 30 + necessaryTitleLabelSize.height + TITLE_DESCRIPTION_PADDING + necessaryDescriptionLabelSize.height;
    
    CGFloat maxHeight = MAX(stationHeight, dataHeight);
    
    // 44 is the default height, return largest of most prominent column height or the default height of 44. 
    return MAX(maxHeight, 44);
}

@end
