
#import <UIKit/UIKit.h>

@class ShuttleRoute;

@interface RouteInfoTitleCell : UITableViewCell {

    
}

@property (nonatomic, strong) IBOutlet UILabel* routeTitleLabel;
@property (nonatomic, strong) IBOutlet UILabel* routeDescriptionLabel;

-(void) setRouteInfo:(ShuttleRoute*) route;

-(CGFloat) heightForCellWithRoute:(ShuttleRoute*) route;

@end
