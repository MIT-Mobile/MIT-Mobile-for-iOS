#import "UITableViewCell+MITUIAdditions.h"
#import "MITUIConstants.h"
#import "SecondaryGroupedTableViewCell.h"

@implementation UITableViewCell (MITUIAdditions)

- (void)applyStandardFonts {
	self.textLabel.font = [UIFont fontWithName:BOLD_FONT size:CELL_STANDARD_FONT_SIZE];
	self.textLabel.textColor = CELL_STANDARD_FONT_COLOR;

	if (self.detailTextLabel != nil) {
		self.detailTextLabel.font = [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE];
		self.detailTextLabel.textColor = CELL_DETAIL_FONT_COLOR;
	}
}


- (void)addAccessoryImage:(UIImage *)image {
	UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
	self.accessoryView = imageView;
	[imageView release];
}

@end
