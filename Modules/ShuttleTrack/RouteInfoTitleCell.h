
#import <UIKit/UIKit.h>

@class ShuttleRoute;

@interface RouteInfoTitleCell : UITableViewCell {

    IBOutlet UIImageView* _backgroundImage;
	IBOutlet UILabel* _routeTitleLabel;
	IBOutlet UILabel* _rotueDescriptionLabel;
}

@property (nonatomic, retain) UILabel* routeTitleLabel;
@property (nonatomic, retain) UILabel* routeDescriptionLabel;

-(void) setRouteInfo:(ShuttleRoute*) route;

-(CGFloat) heightForCellWithRoute:(ShuttleRoute*) route;

@end
