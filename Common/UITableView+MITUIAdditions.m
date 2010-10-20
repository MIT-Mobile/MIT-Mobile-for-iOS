#import "UITableView+MITUIAdditions.h"
#import "MITUIConstants.h"

@implementation UITableView (MITUIAdditions)

- (void)applyStandardColors {
	self.backgroundColor = [UIColor clearColor]; // allows background to show through
	self.separatorColor = TABLE_SEPARATOR_COLOR;
}

- (void)applyStandardCellHeight {
	self.rowHeight = CELL_TWO_LINE_HEIGHT;
}

+ (UIView *)groupedSectionHeaderWithTitle:(NSString *)title {
	UIFont *font = [UIFont boldSystemFontOfSize:STANDARD_CONTENT_FONT_SIZE];
	CGSize size = [title sizeWithFont:font];
	CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 8.0, appFrame.size.width - 20.0, size.height)];
	
	label.text = title;
	label.textColor = GROUPED_SECTION_FONT_COLOR;
	label.font = font;
	label.backgroundColor = [UIColor clearColor];
	
	UIView *labelContainer = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, appFrame.size.width, GROUPED_SECTION_HEADER_HEIGHT)] autorelease];
	labelContainer.backgroundColor = [UIColor clearColor];
	
	[labelContainer addSubview:label];
	[label release];
	
	return labelContainer;
}

+ (UIView *)ungroupedSectionHeaderWithTitle:(NSString *)title {
	UIFont *font = [UIFont boldSystemFontOfSize:STANDARD_CONTENT_FONT_SIZE];
	CGSize size = [title sizeWithFont:font];
	CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, appFrame.size.width - 20.0, size.height)];
	
	label.text = title;
	label.textColor = UNGROUPED_SECTION_FONT_COLOR;
	label.font = font;
	label.backgroundColor = [UIColor clearColor];
	
	UIView *labelContainer = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, appFrame.size.width, UNGROUPED_SECTION_HEADER_HEIGHT)] autorelease];
	labelContainer.backgroundColor = UNGROUPED_SECTION_BACKGROUND_COLOR;
	
	[labelContainer addSubview:label];	
	[label release];
	
	return labelContainer;
}

@end
