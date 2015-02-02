#import "SecondaryGroupedTableViewCell.h"
#import "MITUIConstants.h"

#define SECONDARY_GROUP_VIEW_TAG 999

@implementation SecondaryGroupedTableViewCell

@synthesize secondaryTextLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
		secondaryTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    }
    return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	// remove nonstandard views previously rendered
	UIView *extra = [self.contentView viewWithTag:SECONDARY_GROUP_VIEW_TAG];
	[extra removeFromSuperview];
	
	self.backgroundColor = SECONDARY_GROUP_BACKGROUND_COLOR;
	
	self.textLabel.font = [UIFont boldSystemFontOfSize:CELL_STANDARD_FONT_SIZE];
	self.textLabel.textColor = CELL_STANDARD_FONT_COLOR;
	self.textLabel.backgroundColor = [UIColor clearColor];
	
	if (self.secondaryTextLabel.text != nil) {
		self.secondaryTextLabel.font = [UIFont systemFontOfSize:CELL_DETAIL_FONT_SIZE];
		self.secondaryTextLabel.textColor = CELL_DETAIL_FONT_COLOR;
        self.secondaryTextLabel.highlightedTextColor = [UIColor whiteColor];
		self.secondaryTextLabel.backgroundColor = [UIColor clearColor];		
		self.secondaryTextLabel.tag = SECONDARY_GROUP_VIEW_TAG;
        
        CGSize textSize = [self.textLabel.text sizeWithAttributes:@{NSFontAttributeName: self.textLabel.font}];
        CGSize detailTextSize = [self.secondaryTextLabel.text sizeWithAttributes:@{NSFontAttributeName: self.secondaryTextLabel.font}];
        
		self.secondaryTextLabel.frame = CGRectMake(textSize.width + self.textLabel.frame.origin.x + 4.0, 
												   self.textLabel.frame.origin.y,
												   detailTextSize.width, 
												   self.textLabel.frame.size.height);
		[self.contentView addSubview:self.secondaryTextLabel];
	}
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
