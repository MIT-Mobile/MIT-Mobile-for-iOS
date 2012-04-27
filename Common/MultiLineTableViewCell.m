#import "MultiLineTableViewCell.h"
#import "MITUIConstants.h"
#define DEFAULT_TOP_PADDING CELL_VERTICAL_PADDING
#define DEFAULT_BOTTOM_PADDING CELL_VERTICAL_PADDING
#define DEFAULT_MAIN_FONT [UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE]
#define DEFAULT_DETAIL_FONT [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE]

@implementation MultiLineTableViewCell
@synthesize topPadding, bottomPadding;
@synthesize textLabelLineBreakMode, textLabelNumberOfLines, detailTextLabelLineBreakMode, detailTextLabelNumberOfLines;

static CGFloat plainLabelWidthCheckmarkAccessory = 0;
static CGFloat plainLabelWidthChevronAccessory = 0;
static CGFloat plainLabelWidthImageAccessory = 0;
static CGFloat plainLabelWidthNoAccessory = 0;

static CGFloat groupedLabelWidthCheckmarkAccessory = 0;
static CGFloat groupedLabelWidthChevronAccessory = 0;
static CGFloat groupedLabelWidthImageAccessory = 0;
static CGFloat groupedLabelWidthNoAccessory = 0;

static BOOL s_needsRedrawing = NO;
static NSInteger s_numberOfCellsDrawn = 0;
static NSInteger s_numberOfCells = 0;

- (void) layoutLabel: (UILabel *)label atHeight: (CGFloat)height {
    CGSize labelSize = [label.text sizeWithFont:label.font 
                              constrainedToSize:CGSizeMake(label.frame.size.width, 600.0) 
                                  lineBreakMode:UILineBreakModeWordWrap];
    
    if (label == self.textLabel && textLabelLineBreakMode == UILineBreakModeTailTruncation) {
        CGSize oneLineSize = [label.text sizeWithFont:label.font];
        labelSize.height = (labelSize.height > oneLineSize.height) ? oneLineSize.height * textLabelNumberOfLines : oneLineSize.height;
    } else if (label == self.detailTextLabel && detailTextLabelLineBreakMode == UILineBreakModeTailTruncation) {
        CGSize oneLineSize = [label.text sizeWithFont:label.font];
        labelSize.height = (labelSize.height > oneLineSize.height) ? oneLineSize.height * detailTextLabelNumberOfLines : oneLineSize.height;
    }
    
    label.frame = CGRectMake(label.frame.origin.x, topPadding + height, label.frame.size.width, labelSize.height);
}

- (void) layoutSubviews {
    
	[super layoutSubviews]; // this resizes labels to default size
    
    if ([MultiLineTableViewCell needsRedrawing] && [self.superview isKindOfClass:[UITableView class]]) {
        UITableView *superView = (UITableView *)self.superview;
        CGFloat *cellWidth = [MultiLineTableViewCell cellWidthForTableStyle:superView.style accessoryType:self.accessoryType];
        if (self.textLabel.frame.size.width > *cellWidth) {
            *cellWidth = self.textLabel.frame.size.width;
        }
        if (self.detailTextLabel.frame.size.width > *cellWidth) {
            *cellWidth = self.detailTextLabel.frame.size.width;
        }
        if (s_numberOfCells > 0) s_numberOfCells--;
        s_numberOfCellsDrawn++;
        //NSLog(@"cells left: %d; cells drawn: %d; cells visible: %d", s_numberOfCells, s_numberOfCellsDrawn, [[superView indexPathsForVisibleRows] count]);
        if (*cellWidth > 0 && (s_numberOfCells == 0 || s_numberOfCellsDrawn == [[superView indexPathsForVisibleRows] count])) {
            //NSLog(@"redrawing");
            [MultiLineTableViewCell setNeedsRedrawing:NO];
            [superView reloadData];
        }
    }

    self.textLabel.lineBreakMode = textLabelLineBreakMode;
    self.textLabel.numberOfLines = textLabelNumberOfLines;
    
    self.detailTextLabel.lineBreakMode = detailTextLabelLineBreakMode;
    self.detailTextLabel.numberOfLines = detailTextLabelNumberOfLines;

    if (textLabelNumberOfLines != 1) { // if == 1, the UITableViewCell default is adequate
        [self layoutLabel:self.textLabel atHeight:0];
    }
    
    [self layoutLabel:self.detailTextLabel atHeight:self.textLabel.frame.size.height];

	// make sure any extra views are drawn on top of standard testLabel and detailTextLabel
	NSMutableArray *extraSubviews = [NSMutableArray arrayWithCapacity:[self.contentView.subviews count]];
	for (UIView *aView in self.contentView.subviews) {
		if (aView != self.textLabel && aView != self.detailTextLabel) {
			[extraSubviews addObject:aView];
			[aView removeFromSuperview];
		}
	}
	for (UIView *aView in extraSubviews) {
		[self.contentView addSubview:aView];
	}
}

- (id) initWithStyle: (UITableViewCellStyle)cellStyle reuseIdentifier: (NSString *)reuseIdentifier {
    self = [super initWithStyle:cellStyle reuseIdentifier:reuseIdentifier];
    if (self) {		
		topPadding = DEFAULT_TOP_PADDING;
		bottomPadding = DEFAULT_BOTTOM_PADDING;
        
        textLabelLineBreakMode = UILineBreakModeWordWrap;
        textLabelNumberOfLines = 0;
        
        detailTextLabelLineBreakMode = UILineBreakModeWordWrap;
        detailTextLabelNumberOfLines = 0;
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

+ (void)setNeedsRedrawing:(BOOL)needsRedrawing {
    s_needsRedrawing = needsRedrawing;
    s_numberOfCells = 0;
    s_numberOfCellsDrawn = 0;
}

+ (BOOL)needsRedrawing {
    return s_needsRedrawing;
}

+ (CGFloat *)cellWidthForTableStyle:(UITableViewStyle)style accessoryType:(UITableViewCellAccessoryType)accessoryType {
    
    CGFloat *cellWidth;
    //NSLog(@"tablestyle: %d, accessorytype: %d", style, accessoryType);
    
    switch (style) {
        case UITableViewStyleGrouped:
        {
            switch (accessoryType) {
                case UITableViewCellAccessoryNone:
                    cellWidth = &groupedLabelWidthNoAccessory;
                    break;
                case UITableViewCellAccessoryCheckmark:
                    cellWidth = &groupedLabelWidthCheckmarkAccessory;
                    break;
                case UITableViewCellAccessoryDisclosureIndicator:
                    cellWidth = &groupedLabelWidthChevronAccessory;
                    break;
                case UITableViewCellAccessoryDetailDisclosureButton:
                default: // in default case, be conservative about label width and give maximum width for accessory
                    cellWidth = &groupedLabelWidthImageAccessory;
                    break;
            }
            break;
        }
        case UITableViewStylePlain:
        default:
        {
            switch (accessoryType) {
                case UITableViewCellAccessoryNone:
                    cellWidth = &plainLabelWidthNoAccessory;
                    break;
                case UITableViewCellAccessoryCheckmark:
                    cellWidth = &plainLabelWidthCheckmarkAccessory;
                    break;
                case UITableViewCellAccessoryDisclosureIndicator:
                    cellWidth = &plainLabelWidthChevronAccessory;
                    break;
                case UITableViewCellAccessoryDetailDisclosureButton:
                default: // in default case, be conservative about label width and give maximum width for accessory
                    cellWidth = &plainLabelWidthImageAccessory;
                    break;
            }
            break;
        }
    }
    
    return cellWidth;
}

+ (CGFloat)cellHeightForTableView:(UITableView *)tableView
                             text:(NSString *)text
                       detailText:(NSString *)detailText
                         textFont:(UIFont *)textFont
                       detailFont:(UIFont *)detailFont
                    accessoryType:(UITableViewCellAccessoryType)accessoryType
{
    //NSLog(@"%.1f  %.1f  %.1f  %.1f  |  %.1f  %.1f  %.1f  %.1f", plainLabelWidthCheckmarkAccessory, plainLabelWidthChevronAccessory, 
    //      plainLabelWidthImageAccessory, plainLabelWidthNoAccessory, groupedLabelWidthCheckmarkAccessory,
    //      groupedLabelWidthChevronAccessory, groupedLabelWidthImageAccessory, groupedLabelWidthNoAccessory);
    
    if ([MultiLineTableViewCell needsRedrawing] && s_numberOfCells == 0) {
        // call delegate methods instead of tableView methods because the latter
        // can call other delegate methods (heightForRowAtIndexPath) which
        // cause an infinite loop with this function
        NSInteger numberOfSections = [tableView.dataSource numberOfSectionsInTableView:tableView];
        for (NSInteger i = 0; i < numberOfSections; i++) {
            s_numberOfCells += [tableView.dataSource tableView:tableView numberOfRowsInSection:i];
        }
        //NSLog(@"number of cells: %d", s_numberOfCells);
    }
    
    if ([MultiLineTableViewCell needsRedrawing]) {
        return [tableView rowHeight];
    }
    
    CGFloat *cellWidth = [MultiLineTableViewCell cellWidthForTableStyle:tableView.style accessoryType:accessoryType];
    
    if (*cellWidth == 0.0) {
        // we will only get this far once per type of cell
        [MultiLineTableViewCell setNeedsRedrawing:YES];
        //s_numberOfCells = 0;
        return [tableView rowHeight];
    }
    
	CGFloat mainHeight = [text sizeWithFont:textFont
                          constrainedToSize:CGSizeMake(*cellWidth, 600.0)
                              lineBreakMode:UILineBreakModeWordWrap].height;
    
	CGFloat detailHeight = (detailText) ? [detailText sizeWithFont:detailFont
                                                 constrainedToSize:CGSizeMake(*cellWidth, 600.0)
                                                     lineBreakMode:UILineBreakModeWordWrap].height : 0;
    
	return mainHeight + detailHeight + CELL_VERTICAL_PADDING * 2;
}

+ (CGFloat)cellHeightForTableView:(UITableView *)tableView
                             text:(NSString *)text
                       detailText:(NSString *)detailText
                    accessoryType:(UITableViewCellAccessoryType)accessoryType
{
    return [MultiLineTableViewCell cellHeightForTableView:tableView
                                                     text:text
                                               detailText:detailText
                                                 textFont:DEFAULT_MAIN_FONT
                                               detailFont:DEFAULT_DETAIL_FONT
                                            accessoryType:accessoryType];
}
@end

