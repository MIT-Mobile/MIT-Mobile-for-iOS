#import "MultiLineTableViewCell.h"
#import "MITUIConstants.h"
#define DEFAULT_TOP_PADDING CELL_VERTICAL_PADDING
#define DEFAULT_BOTTOM_PADDING CELL_VERTICAL_PADDING
#define DEFAULT_MAIN_FONT [UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE]
#define DEFAULT_DETAIL_FONT [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE]

@implementation MultiLineTableViewCell
@synthesize topPadding, bottomPadding;

+ (void) layoutLabel: (UILabel *)label atHeight: (CGFloat)height topPadding: (CGFloat)topPadding {
	CGSize labelSize = [label.text sizeWithFont:label.font 
						constrainedToSize:CGSizeMake(label.frame.size.width, 600.0) 
						lineBreakMode:UILineBreakModeWordWrap];
	label.frame = CGRectMake(label.frame.origin.x, 
									  topPadding + height, 
									  label.frame.size.width, 
									  labelSize.height);
	label.lineBreakMode = UILineBreakModeWordWrap;
	label.numberOfLines = 0;
}

+ (CGFloat) defaultTopPadding {
	return DEFAULT_TOP_PADDING;
}

- (void) layoutLabel: (UILabel *)label atHeight: (CGFloat)height {
	[MultiLineTableViewCell layoutLabel:label atHeight:height topPadding:topPadding];
}

- (void) layoutSubviews {
	[super layoutSubviews];

	[self layoutLabel:self.textLabel atHeight:0];
	[self layoutLabel:self.detailTextLabel atHeight:self.textLabel.frame.size.height];
}

- (id) initWithStyle: (UITableViewCellStyle)cellStyle reuseIdentifier: (NSString *)reuseIdentifier {
    if(self = [super initWithStyle:cellStyle reuseIdentifier:reuseIdentifier]) {		
		topPadding = DEFAULT_TOP_PADDING;
		bottomPadding = DEFAULT_BOTTOM_PADDING;
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

+ (CGFloat) widthAdjustmentForAccessoryType: (UITableViewCellAccessoryType)accessoryType isGrouped: (BOOL)isGrouped {
	
	CGFloat adjustment = 0;
	switch (accessoryType) {
		case UITableViewCellAccessoryNone:
			adjustment = 0;
			break;
		case UITableViewCellAccessoryDisclosureIndicator:
			adjustment = 20;
			break;
		case UITableViewCellAccessoryDetailDisclosureButton:
			adjustment = 33;
			break;
		case UITableViewCellAccessoryCheckmark:
			adjustment = 20;
			break;
	}
	
	if(isGrouped) {
		adjustment = adjustment + 21;
	}
	
	return adjustment;
}
	

+ (CGFloat) cellHeightForTableView: (UITableView *)tableView
							  main: (NSString *)main
							detail: (NSString *)detail
					 accessoryType: (UITableViewCellAccessoryType)accessoryType
						 isGrouped: (BOOL)isGrouped {
	
	return [self 
		cellHeightForTableView:tableView
		main:main
		mainFont:DEFAULT_MAIN_FONT
		detail:detail
		detailFont:DEFAULT_DETAIL_FONT
		widthAdjustment:[self widthAdjustmentForAccessoryType:accessoryType isGrouped:isGrouped]
		topPadding:DEFAULT_TOP_PADDING
		bottomPadding:DEFAULT_BOTTOM_PADDING];
}

+ (CGFloat) cellHeightForTableView: (UITableView *)tableView
							  main: (NSString *)main
							detail: (NSString *)detail 
					 accessoryType: (UITableViewCellAccessoryType)accessoryType
						 isGrouped: (BOOL)isGrouped
						topPadding: (CGFloat)topPadding {
	
	return [self cellHeightForTableView:tableView
		main:main
		mainFont:DEFAULT_MAIN_FONT
		detail:detail
		detailFont:DEFAULT_DETAIL_FONT
		widthAdjustment:[self widthAdjustmentForAccessoryType:accessoryType isGrouped:isGrouped]
		topPadding:topPadding
		bottomPadding:DEFAULT_BOTTOM_PADDING];
}

+ (CGFloat) cellHeightForTableView: (UITableView *)tableView
							  main: (NSString *)main 
							detail: (NSString *)detail 
				   widthAdjustment: (CGFloat)widthAdjustment {
	
	return [self cellHeightForTableView:tableView
		main:main
		mainFont:DEFAULT_MAIN_FONT
		detail:detail
		detailFont:DEFAULT_DETAIL_FONT
		widthAdjustment:widthAdjustment
		topPadding:DEFAULT_TOP_PADDING
		bottomPadding:DEFAULT_BOTTOM_PADDING];
}	

+ (CGFloat) cellHeightForTableView: (UITableView *)tableView
							  main: (NSString *)main 
						  mainFont: (UIFont *)mainFont
							detail: (NSString *)detail 
						detailFont: (UIFont *)detailFont
					accessoryType: (UITableViewCellAccessoryType)accessoryType 
						 isGrouped: (BOOL)isGrouped {
	
	return [self cellHeightForTableView:tableView
		main:main
		mainFont:mainFont
		detail:detail 
		detailFont:detailFont
		widthAdjustment:[self widthAdjustmentForAccessoryType:accessoryType isGrouped:isGrouped]
		topPadding:DEFAULT_TOP_PADDING
		bottomPadding:DEFAULT_BOTTOM_PADDING];
}	

+ (CGFloat) cellHeightForTableView: (UITableView *)tableView
							  main: (NSString *)main 
						  mainFont: (UIFont *)mainFont
							detail: (NSString *)detail 
						detailFont: (UIFont *)detailFont
				   widthAdjustment: (CGFloat)widthAdjustment 
						topPadding: (CGFloat)topPadding 
					 bottomPadding: (CGFloat)bottomPadding {
	
	CGFloat width = tableView.frame.size.width - widthAdjustment - 21.0;

	CGFloat mainHeight = [main 
		sizeWithFont:mainFont
		constrainedToSize:CGSizeMake(width, 600.0)         
		lineBreakMode:UILineBreakModeWordWrap].height;
	
	CGFloat detailHeight;
	if(detail) {
		detailHeight = [detail
			sizeWithFont:detailFont
			constrainedToSize:CGSizeMake(width, 600.0)         
			lineBreakMode:UILineBreakModeWordWrap].height;
	} else {
		detailHeight = 0;
	}

	return (mainHeight + detailHeight) + topPadding + bottomPadding;
}
@end

