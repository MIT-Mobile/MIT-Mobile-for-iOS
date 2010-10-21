#import <UIKit/UIKit.h>
#import "MITMobileWebAPI.h"

@interface CalendarCategoriesViewController : UITableViewController <JSONLoadedDelegate> {

	NSArray *categories;
	
}

@property (nonatomic, retain) NSArray *categories;

@end
