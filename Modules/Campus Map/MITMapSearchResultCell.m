
#import "MITMapSearchResultCell.h"


@implementation MITMapSearchResultCell


- (void) layoutSubviews
{
	[super layoutSubviews];
	
	// adjust textLabel to fit height of contents
	self.textLabel.font = [UIFont systemFontOfSize:17];
	CGSize labelSize = [self.textLabel.text sizeWithFont:self.textLabel.font 
									   constrainedToSize:CGSizeMake(self.textLabel.frame.size.width, 200.0) 
										   lineBreakMode:UILineBreakModeWordWrap];
	self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x, 
									  6.0, 
									  self.textLabel.frame.size.width, 
									  labelSize.height);
	self.textLabel.lineBreakMode = UILineBreakModeWordWrap;
	self.textLabel.numberOfLines = 0;
	
	// adjust detailTextLabel to fit height of contents
	self.detailTextLabel.font = [UIFont systemFontOfSize:14];
	
	labelSize = [self.detailTextLabel.text sizeWithFont:self.detailTextLabel.font 
									  constrainedToSize:CGSizeMake(self.detailTextLabel.frame.size.width, 200.0) 
										  lineBreakMode:UILineBreakModeWordWrap];
	self.detailTextLabel.frame = CGRectMake(self.detailTextLabel.frame.origin.x, 
											6.0 + self.textLabel.frame.size.height,
											self.detailTextLabel.frame.size.width, 
											labelSize.height);
	self.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
	self.detailTextLabel.numberOfLines = 0;	

}

-(CGFloat) projectedHeight
{
	
	CGSize labelSize = [self.textLabel.text sizeWithFont:[UIFont systemFontOfSize:17]
									   constrainedToSize:CGSizeMake(self.textLabel.frame.size.width, 200.0) 
										   lineBreakMode:UILineBreakModeWordWrap];
	
	
	
	CGSize labelSize2 = [self.detailTextLabel.text sizeWithFont:[UIFont systemFontOfSize:14]
											  constrainedToSize:CGSizeMake(self.detailTextLabel.frame.size.width, 200.0) 
												  lineBreakMode:UILineBreakModeWordWrap];
	
	return 6.0 + labelSize.height + labelSize2.height;
}

@end
