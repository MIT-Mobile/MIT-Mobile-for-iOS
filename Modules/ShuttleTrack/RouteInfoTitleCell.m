
#import "RouteInfoTitleCell.h"
#import "ShuttleRoute.h"

@implementation RouteInfoTitleCell
@synthesize routeTitleLabel = _routeTitleLabel;
@synthesize routeDescriptionLabel = _rotueDescriptionLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        // Initialization code
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)dealloc {
    [super dealloc];
}

-(void) setRouteInfo:(ShuttleRoute*)routeInfo
{
	if(nil == routeInfo.title)
		self.routeTitleLabel.text = @"Route";
	else {
		self.routeTitleLabel.text = routeInfo.title;
	}

	UIImage* backgroundImagePattern = [UIImage imageNamed:MITImageNameBackground];
	self.contentView.backgroundColor = [UIColor colorWithPatternImage:backgroundImagePattern];

	CGSize descriptionSize = [routeInfo.fullSummary sizeWithFont:self.routeDescriptionLabel.font
										 constrainedToSize:CGSizeMake(self.routeDescriptionLabel.frame.size.width, 400)
											 lineBreakMode:self.routeDescriptionLabel.lineBreakMode];
	
	self.routeDescriptionLabel.frame = CGRectMake(self.routeDescriptionLabel.frame.origin.x,
												  self.routeDescriptionLabel.frame.origin.y,
												  self.routeDescriptionLabel.frame.size.width,
												  descriptionSize.height);
	
	self.routeDescriptionLabel.text = routeInfo.fullSummary;
	
}

-(CGFloat) heightForCellWithRoute:(ShuttleRoute*) route;
{
	CGSize descriptionSize = [route.fullSummary sizeWithFont:self.routeDescriptionLabel.font
											   constrainedToSize:CGSizeMake(self.routeDescriptionLabel.frame.size.width, 400)
												   lineBreakMode:self.routeDescriptionLabel.lineBreakMode];
	
	CGFloat height = self.routeDescriptionLabel.frame.origin.y ;
	height += descriptionSize.height;
	height += 10;
	return height;
}

@end
