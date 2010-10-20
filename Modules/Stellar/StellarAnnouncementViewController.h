
#import <UIKit/UIKit.h>
#import "StellarAnnouncement.h"

@interface StellarAnnouncementViewController : UITableViewController {
	StellarAnnouncement *announcement;
	
	NSDateFormatter *dateFormatter;
	
	UIFont *titleFont;
	UIFont *dateFont;
	UIFont *textFont;	
}

- (id) initWithAnnouncement: (StellarAnnouncement *)announcement;
@end
