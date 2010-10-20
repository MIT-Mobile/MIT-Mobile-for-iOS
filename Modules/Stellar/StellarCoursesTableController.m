
#import "StellarCoursesTableController.h"
#import "StellarCourse.h"
#import "StellarClassesTableController.h"
#import "UITableView+MITUIAdditions.h"
#import "UITableViewCell+MITUIAdditions.h"


@implementation StellarCoursesTableController
@synthesize courseGroup;

- (id) initWithCourseGroup: (StellarCourseGroup *)aCourseGroup {
	if(self = [super initWithStyle:UITableViewStyleGrouped]) {
		self.courseGroup = aCourseGroup;
	}
	return self;
}

- (void) dealloc {
	[courseGroup release];
	[super dealloc];
}

- (void) viewDidLoad {
	self.title = self.courseGroup.title;
	[self.tableView applyStandardColors];
	[self.tableView applyStandardCellHeight];
}

// "DataSource" methods
- (NSInteger) numberOfSectionsInTableView: (UITableView *)tableView {
	return 1;
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StellarCourses"];
	if(cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"StellarCourses"] autorelease];
		[cell applyStandardFonts];
	}
	
	StellarCourse *stellarCourse = (StellarCourse *)[self.courseGroup.courses objectAtIndex:indexPath.row];
	
	cell.textLabel.text = [@"Course " stringByAppendingString:stellarCourse.number];
	cell.detailTextLabel.text = stellarCourse.title;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return cell;
}

- (NSInteger) tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section {
	return [self.courseGroup.courses count];
}

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath {
	[self.navigationController
		pushViewController: [[[StellarClassesTableController alloc] 
			initWithCourse: (StellarCourse *)[self.courseGroup.courses objectAtIndex:indexPath.row]] autorelease]
		animated:YES];
}




@end
