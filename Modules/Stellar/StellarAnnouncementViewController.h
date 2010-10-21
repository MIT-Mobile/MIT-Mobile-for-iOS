#import <UIKit/UIKit.h>
#import "StellarAnnouncement.h"
#import "MITModuleURL.h"

@interface StellarAnnouncementViewController : UITableViewController {
	StellarAnnouncement *announcement;
	
	NSDateFormatter *dateFormatter;
	
	UIFont *titleFont;
	UIFont *dateFont;
	UIFont *textFont;	
	
	MITModuleURL *url;
	NSUInteger rowIndex;
}

- (id) initWithAnnouncement: (StellarAnnouncement *)announcement rowIndex: (NSUInteger)index;
@end
