
#import "StellarCourseGroup.h"
#import "StellarCourse.h"

NSInteger courseNameCompare(id course1, id course2, void *context);

@implementation StellarCourseGroup
@synthesize title, courses;

- (id) initWithTitle: (NSString *)aTitle courses:(NSArray *)aCourseGroup {
	if(self = [super init]) {
		self.title = aTitle;
		self.courses = aCourseGroup;
	}
	return self;
}

+ (NSArray *) allCourseGroups:(NSArray *)stellarCourses {
	NSArray *courseCriterias = [NSArray arrayWithObjects:
		[CourseGroupCriteria numericLower:@"1" upper:@"11"],
		[CourseGroupCriteria numericLower:@"11" upper:@"21"],
		[CourseGroupCriteria numericLower:@"21"],
		[CourseGroupCriteria nonNumeric],
		nil];
	
	
	NSMutableArray *courseGroups = [NSMutableArray array];
	for(CourseGroupCriteria *criteria in courseCriterias) {
		NSMutableArray *courseGroup = [NSMutableArray array];
		for(StellarCourse *course in stellarCourses) {
			if([criteria isInGroup:course.number]) {
				[courseGroup addObject:course];
			}
		}
		
		NSArray *sortedCourseGroup = [courseGroup sortedArrayUsingFunction:courseNameCompare context:NULL];
		if([sortedCourseGroup count] > 0) {
			NSString *title;
			if([criteria isNumeric]) {
				title = [@"Courses " stringByAppendingString:((StellarCourse *)[sortedCourseGroup objectAtIndex:0]).number];
				title = [title stringByAppendingString:@"-"];
				title = [title stringByAppendingString:((StellarCourse *)[sortedCourseGroup lastObject]).number];
			} else {
				title = @"Other Courses";
			}
				
			[courseGroups addObject:[[[StellarCourseGroup alloc] initWithTitle:title courses:sortedCourseGroup] autorelease]];
		}	
	}
	return courseGroups;
}
	

- (void) dealloc {
	[title release];
	[courses release];
	[super dealloc];
}
	
@end

@implementation CourseGroupCriteria
@synthesize lower, upper;

+ (CourseGroupCriteria *) numericLower: (NSString *)lower {
		return [[[CourseGroupCriteria alloc] initNumeric:YES lower:lower upper:nil] autorelease];
}

+ (CourseGroupCriteria *) numericLower: (NSString *)lower upper: (NSString *)upper {
	return [[[CourseGroupCriteria alloc] initNumeric:YES lower:lower upper:upper] autorelease];
}

+ (CourseGroupCriteria *) nonNumeric {
	return [[[CourseGroupCriteria alloc] initNumeric:NO lower:nil upper:nil] autorelease];
}

- (id) initNumeric: (BOOL)aNumeric lower: (NSString *)aLower upper: (NSString *)aUpper {
	[super init];
	self.lower = aLower;
	self.upper = aUpper;
	numeric = aNumeric;
	return self;
}
	
- (BOOL) isInGroup: (NSString *)groupName {
	BOOL isNumeric;
	
	if([groupName compare:@"0"] == NSOrderedAscending) {
		isNumeric = NO;
	} else if([groupName compare:@"9"] == NSOrderedDescending) {
		isNumeric = NO;
	} else {
		isNumeric = YES;
	}
	
	if(numeric) {
		if(!isNumeric) {
			return NO;
		}
		
		if([groupName compare:lower options:NSNumericSearch] == NSOrderedAscending) {
			return NO;
		}
		
		if(upper == nil) {
			return YES;
		}
		
		return ([groupName compare:upper options:NSNumericSearch] == NSOrderedAscending);
	} else {
		return !isNumeric;
	}
}

- (BOOL) isNumeric {
	return numeric;
}

@end

NSInteger courseNameCompare(id course1, id course2, void *context) {
	return [((StellarCourse *)course1).number compare:((StellarCourse *)course2).number options:NSNumericSearch];
}
