#import "DiningHallMenuItemTableCell.h"
#import "UIKit+MITAdditions.h"
#import "UIImage+PDF.h"

#define TITLE_DESCRIPTION_PADDING 4
#define TYPE_ICON_SIZE 24

@interface DiningHallMenuItemTableCell()

@property (nonatomic, strong) UILabel * station;
@property (nonatomic, strong) UILabel * title;
@property (nonatomic, strong) UILabel * subtitle;

@property (nonatomic, strong) UIView * typeContainer;

@end

const NSInteger kStationWidth = 70;
const NSInteger kTitleWidth = 160;
const NSInteger kSubtitleWidth = 160;

@implementation DiningHallMenuItemTableCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
                                                                            // heights are initialized to be minimum allowed. Height will vary
        
        CGRect stationFrame = CGRectMake(10, 15, kStationWidth, 14);
        CGRect titleFrame = CGRectMake(90, 15, kTitleWidth, 14);
        CGRect subtitleFrame = CGRectMake(90, 41, kSubtitleWidth, 12);
        
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
            stationFrame.origin.x = 15.;
            titleFrame.origin.x += 5.;
            titleFrame.size.width -= 5.;
            subtitleFrame.origin.x += 5.;
            subtitleFrame.size.width -= 5.;
            self.separatorInset = UIEdgeInsetsMake(0., titleFrame.origin.x, 0., 0.);
        }

        self.station        = [[UILabel alloc] initWithFrame:stationFrame];
        self.title          = [[UILabel alloc] initWithFrame:titleFrame];
        self.subtitle       = [[UILabel alloc] initWithFrame:subtitleFrame];

        [self formatLabel:self.station withFont:[[self class] primaryFont]];
        [self formatLabel:self.title withFont:[[self class] primaryFont]];
        [self formatLabel:self.subtitle withFont:[[self class] secondaryFont]];
        
        self.typeContainer  = [[UIView alloc] initWithFrame:CGRectMake(265, 15, (TYPE_ICON_SIZE * 2) + 5, TYPE_ICON_SIZE)];   // if more than 2 this view will need to resize
        
        [self.contentView addSubview:self.station];
        [self.contentView addSubview:self.title];
        [self.contentView addSubview:self.subtitle];
        [self.contentView addSubview:self.typeContainer];
    }
    return self;
}

- (void) formatLabel:(UILabel *) label withFont:(UIFont *) font
{
    label.numberOfLines     = 0;
    label.lineBreakMode     = NSLineBreakByWordWrapping;
    label.font              = font;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    [self adjustSizeForLabel:self.station];
    [self adjustSizeForLabel:self.title];
    [self adjustSizeForLabel:self.subtitle];
    
    // sizes have beeen adjusted, need to layout origin
    // subtitle origin should be the only dynamic origin
    CGRect frame = self.subtitle.frame;
    frame.origin = CGPointMake(frame.origin.x, CGRectGetMaxY(self.title.frame) + TITLE_DESCRIPTION_PADDING);
    self.subtitle.frame = frame;
    
    if ([self.dietaryImagePaths count] > 2) {
        self.typeContainer.frame = CGRectMake(265, 15, 45, 45);
    }
    
    [self.typeContainer removeAllSubviews];     // start with blank slate every time so reuse does not get corrupt
    [self layoutDietaryTypes];
    
}

- (void) layoutDietaryTypes
{
    CGSize iconSize = CGSizeMake(TYPE_ICON_SIZE, TYPE_ICON_SIZE);
    int maxIcons = 4;
    NSMutableArray *icons = [NSMutableArray arrayWithCapacity:maxIcons];
    for (NSString *imagePath in self.dietaryImagePaths) {
        UIImage *image = [UIImage imageWithPDFNamed:imagePath fitSize:iconSize];

        if (image != nil) {
            [icons addObject:image];
        }
    }
    
    for (int i = 0; i < [icons count]; i++) {
        UIImageView *iconView = [[UIImageView alloc] initWithImage:icons[i]];
        // there can only be a maximum of four icons, they are aligned like so :    1 0
        //                                                                          3 2
        // full layout subtitle can be found in the spec: https://jira.mit.edu/jira/secure/attachment/26097/house+menu.pdf
        iconView.center = CGPointMake(35 - (iconSize.width + 5) * (i % 2), 10 + (iconSize.height + 5) * (i >= 2));
        [self.typeContainer addSubview:iconView];
    }
}

- (void) adjustSizeForLabel:(UILabel *)label
{
    CGSize maximumLabelSize = CGSizeMake(CGRectGetWidth(label.bounds), CGFLOAT_MAX);
    
    CGSize necessaryLabelSize = [[label text] sizeWithFont:label.font constrainedToSize:maximumLabelSize lineBreakMode:label.lineBreakMode];
    
    CGRect newFrame = label.frame;
    newFrame.size   = CGSizeMake(maximumLabelSize.width, necessaryLabelSize.height);    // only ever change the height
    label.frame     = newFrame;
}


#pragma mark - Internal Class Helpers

+ (UIFont *) primaryFont
{
    return [UIFont boldSystemFontOfSize:14];
}

+ (UIFont *) secondaryFont
{
    return [UIFont systemFontOfSize:14];
}

#pragma mark - Class Methods
+ (CGFloat) cellHeightForCellWithStation:(NSString *)station title:(NSString *) title subtitle:(NSString *)subtitle
{
    CGFloat stationWidth        = kStationWidth;
    CGFloat titleWidth          = kTitleWidth;
    CGFloat subtitleWidth       = kSubtitleWidth;
    
    CGSize maximumStationSize       = CGSizeMake(stationWidth, CGFLOAT_MAX);
    CGSize maximumTitleSize         = CGSizeMake(titleWidth, CGFLOAT_MAX);
    CGSize maximumSubtitleSize      = CGSizeMake(subtitleWidth, CGFLOAT_MAX);
    
    CGSize necessaryStationLabelSize        = [station sizeWithFont:[self primaryFont] constrainedToSize:maximumStationSize lineBreakMode:NSLineBreakByWordWrapping];
    CGSize necessaryTitleLabelSize          = [title sizeWithFont:[self primaryFont] constrainedToSize:maximumTitleSize lineBreakMode:NSLineBreakByWordWrapping];
    CGSize necessarySubtitleLabelSize    = [subtitle sizeWithFont:[self secondaryFont] constrainedToSize:maximumSubtitleSize lineBreakMode:NSLineBreakByWordWrapping];
    
    CGFloat stationHeight   = 30 + necessaryStationLabelSize.height;
    CGFloat dataHeight      = 30 + necessaryTitleLabelSize.height + TITLE_DESCRIPTION_PADDING + necessarySubtitleLabelSize.height;
    
    CGFloat maxHeight = MAX(stationHeight, dataHeight);
    
    // 44 is the default height, return largest of most prominent column height or the default height of 44. 
    return MAX(maxHeight, 44);
}

@end
