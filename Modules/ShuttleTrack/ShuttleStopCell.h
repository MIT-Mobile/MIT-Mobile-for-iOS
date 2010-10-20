
#import <UIKit/UIKit.h>
@class ShuttleStop;

@interface ShuttleStopCell : UITableViewCell 
{
	IBOutlet UIImageView* _shuttleStopImageView;
	IBOutlet UILabel* _shuttleNameLabel;
	IBOutlet UILabel* _shuttleTimeLabel;
}

-(void) setShuttleInfo:(ShuttleStop*)shuttleStop;

@end
