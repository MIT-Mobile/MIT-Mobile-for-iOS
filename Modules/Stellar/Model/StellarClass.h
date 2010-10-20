
#import <CoreData/CoreData.h>

@class StellarClassTime;
@class StellarAnnouncement;
@class StellarStaffMember;
@class StellarCourse;

@interface StellarClass :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * masterSubjectId;
@property (nonatomic, retain) NSNumber * isFavorited;
@property (nonatomic, retain) NSDate * lastAccessedDate;
@property (nonatomic, retain) NSString * term;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * blurb;
@property (nonatomic, retain) NSNumber * isRecent;
@property (nonatomic, retain) NSSet* times;
@property (nonatomic, retain) NSSet* announcement;
@property (nonatomic, retain) NSSet* staff;
@property (nonatomic, retain) NSSet* course;

@end


@interface StellarClass (CoreDataGeneratedAccessors)
- (void)addTimesObject:(StellarClassTime *)value;
- (void)removeTimesObject:(StellarClassTime *)value;
- (void)addTimes:(NSSet *)value;
- (void)removeTimes:(NSSet *)value;

- (void)addAnnouncementObject:(StellarAnnouncement *)value;
- (void)removeAnnouncementObject:(StellarAnnouncement *)value;
- (void)addAnnouncement:(NSSet *)value;
- (void)removeAnnouncement:(NSSet *)value;

- (void)addStaffObject:(StellarStaffMember *)value;
- (void)removeStaffObject:(StellarStaffMember *)value;
- (void)addStaff:(NSSet *)value;
- (void)removeStaff:(NSSet *)value;

- (void)addCourseObject:(StellarCourse *)value;
- (void)removeCourseObject:(StellarCourse *)value;
- (void)addCourse:(NSSet *)value;
- (void)removeCourse:(NSSet *)value;

@end

