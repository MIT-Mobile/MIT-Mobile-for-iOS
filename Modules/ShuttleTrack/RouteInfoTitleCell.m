
#import "RouteInfoTitleCell.h"
#import "ShuttleRoute.h"

@implementation RouteInfoTitleCell
@synthesize routeTitleLabel = _routeTitleLabel;
@synthesize routeDescriptionLabel = _rotueDescriptionLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}
/*
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
*/
- (void)layoutSubviews {
    [super layoutSubviews];
    _backgroundImage.image = [UIImage imageNamed:@"shuttle/shuttle_routelist_header.png"];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    _backgroundImage.frame = frame;    
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
