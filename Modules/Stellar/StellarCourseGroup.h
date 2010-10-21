
#import <Foundation/Foundation.h>

@interface StellarCourseGroup : NSObject {
	NSString *title;
	NSArray *courses;
}

@property (retain) NSString *title;
@property (retain) NSArray *courses;

- (id) initWithTitle: (NSString *)title courses:(NSArray *)courseGroup;
- (NSString *) serialize;
+ (StellarCourseGroup *) deserialize: (NSString *)serializedCourseGroup;
+ (NSArray *) allCourseGroups: (NSArray *)stellarCourses;
@end

@interface CourseGroupCriteria : NSObject {
	NSString *lower;
	NSString *upper;
	BOOL numeric;
}

@property (retain) NSString *lower;
@property (retain) NSString *upper;

+ (CourseGroupCriteria *) numericLower: (NSString *)lower;
+ (CourseGroupCriteria *) numericLower: (NSString *)lower upper: (NSString *)upper;
+ (CourseGroupCriteria *) nonNumeric;

- (id) initNumeric: (BOOL)numeric lower: (NSString *)lower upper: (NSString *)upper;

- (BOOL) isInGroup: (NSString *)groupName;

- (BOOL) isNumeric;

@end


