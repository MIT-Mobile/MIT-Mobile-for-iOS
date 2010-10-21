#import <Foundation/Foundation.h>
#import "StellarCourseGroup.h"
#import "MITModuleURL.h"

@interface StellarCoursesTableController : UITableViewController {
	StellarCourseGroup *courseGroup;
	MITModuleURL *url;

}

@property (retain) StellarCourseGroup *courseGroup;
@property (readonly) MITModuleURL *url;

- (id) initWithCourseGroup: (StellarCourseGroup *)courseGroup;
@end
