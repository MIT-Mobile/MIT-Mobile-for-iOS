
#import <Foundation/Foundation.h>
#import "StellarCourseGroup.h"

@interface StellarCoursesTableController : UITableViewController {
	StellarCourseGroup *courseGroup;

}

@property (retain) StellarCourseGroup *courseGroup;

- (id) initWithCourseGroup: (StellarCourseGroup *)courseGroup;
@end
