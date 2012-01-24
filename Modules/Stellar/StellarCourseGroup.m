#import "StellarCourseGroup.h"
#import "StellarCourse.h"
#import "StellarModel.h"

NSInteger courseNameCompare(id course1, id course2, void *context);
NSString *stripLetters(NSString *courseNumber);

@implementation StellarCourseGroup
@synthesize title, courses;

- (id) initWithTitle: (NSString *)aTitle courses:(NSArray *)aCourseGroup {
	self = [super init];
	if (self) {
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
				NSString *firstCourseNumber = stripLetters(((StellarCourse *)[sortedCourseGroup objectAtIndex:0]).number);
				NSString *lastCourseNumber = stripLetters(((StellarCourse *)[sortedCourseGroup lastObject]).number);
				title = [NSString stringWithFormat:@"Courses %@-%@", firstCourseNumber, lastCourseNumber];
			} else {
				title = @"Other Courses";
			}
				
			[courseGroups addObject:[[[StellarCourseGroup alloc] initWithTitle:title courses:sortedCourseGroup] autorelease]];
		}	
	}
	return courseGroups;
}

- (NSString *) serialize {
	BOOL first = YES;
	NSMutableString *coursesString = [NSMutableString string];
	for (StellarCourse *course in courses) {
		if (!first) {
			[coursesString appendString:@"-"];
		} else {
			first = NO;
		}
		[coursesString appendString:course.number];
	}
	
	return [NSString stringWithFormat:@"%@:%@", title, coursesString];
}
	
+ (StellarCourseGroup *) deserialize: (NSString *)serializedCourseGroup {
	NSArray *partsByColon = [serializedCourseGroup componentsSeparatedByString:@":"];
	NSString *title = [partsByColon objectAtIndex:0];
	NSArray *courseIds = [[partsByColon objectAtIndex:1] componentsSeparatedByString:@"-"];
	NSMutableArray *courses = [NSMutableArray arrayWithCapacity:courseIds.count];
	for (NSString *courseId in courseIds) {
		StellarCourse *course = [StellarModel courseWithId:courseId];
		if (course) {
			[courses addObject:course];
		} else {
			// if we fail to look up a course
			// consider the whole deserialization a failure
			return nil;
		}
	}
	return [[[StellarCourseGroup alloc] initWithTitle:title courses:courses] autorelease];
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
	self = [super init];
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

NSString* stripLetters(NSString *courseNumber) {
	NSString *noLetters = @"";
	NSCharacterSet *digits = [NSCharacterSet decimalDigitCharacterSet];
	for (NSUInteger i=0; i < courseNumber.length; i++) {
		unichar aChar = [courseNumber characterAtIndex:i];
		if ([digits characterIsMember:aChar]) {
			noLetters = [NSString stringWithFormat:@"%@%C", noLetters, aChar];
		}
	}
	return noLetters;
} 
