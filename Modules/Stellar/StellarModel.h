#import <Foundation/Foundation.h>
#import "ConnectionWrapper.h"
#import "StellarCourse.h"
#import "StellarClass.h"
#import "StellarClassTime.h"
#import "StellarStaffMember.h"
#import "MITMobileWebAPI.h"

extern NSString * const MyStellarChanged;

#pragma mark Course Loading 
@protocol CoursesLoadedDelegate <NSObject>
- (void) coursesLoaded;
@end

@interface CoursesRequest : NSObject <JSONLoadedDelegate> {
	id<CoursesLoadedDelegate> coursesLoadedDelegate;
}
@property(nonatomic, retain) id<CoursesLoadedDelegate> coursesLoadedDelegate;

- (id) initWithCoursesDelegate: (id<CoursesLoadedDelegate>)delegate;
@end

#pragma mark Class List Loading

@protocol ClassesLoadedDelegate <NSObject>
- (void) classesLoaded: (NSArray *)classes;
- (void) handleCouldNotReachStellar;
- (id<UIAlertViewDelegate>) standardErrorAlertDelegate;  
@end

@interface ClassesRequest : NSObject <JSONLoadedDelegate> {
	id<ClassesLoadedDelegate> classesLoadedDelegate;
	StellarCourse *stellarCourse;
}
@property(nonatomic, retain) id<ClassesLoadedDelegate> classesLoadedDelegate;
@property(nonatomic, retain) StellarCourse *stellarCourse;

- (id) initWithDelegate: (NSObject<ClassesLoadedDelegate>*)delegate course: (StellarCourse *)stellarCourse;
- (void) notifyClassesLoadedDelegate;
- (void) markCourseAsNew;
@end

@interface ClassesChecksumRequest : NSObject <JSONLoadedDelegate> {
	ClassesRequest *classesRequest;
}
- (id) initWithClassesRequest:(ClassesRequest *)aClassesRequest;
@end

#pragma mark Class Info Loading

@protocol ClassInfoLoadedDelegate <NSObject>
- (void) generalClassInfoLoaded: (StellarClass *)class;
- (void) initialAllClassInfoLoaded: (StellarClass *)class;
- (void) finalAllClassInfoLoaded: (StellarClass *)class;
- (void) handleClassNotFound;
- (void) handleCouldNotReachStellar;
@end

@interface ClassInfoRequest : NSObject <JSONLoadedDelegate> {
	id<ClassInfoLoadedDelegate> classInfoLoadedDelegate;
}

@property (nonatomic, retain) id<ClassInfoLoadedDelegate> classInfoLoadedDelegate;

- (id) initWithClassInfoDelegate: (id<ClassInfoLoadedDelegate>) delegate;
@end

@protocol ClassesSearchDelegate <NSObject>
- (void) searchComplete: (NSArray *)classes searchTerms: (NSString *)searchTerms;
- (void) handleCouldNotReachStellarWithSearchTerms: (NSString *)searchTerms;
@end

@interface ClassesSearchRequest : NSObject <JSONLoadedDelegate> {
	id<ClassesSearchDelegate> classesSearchDelegate;
	NSString *searchTerms;
}

- (id) initWithDelegate: (id<ClassesSearchDelegate>)delegate searchTerms: (NSString *)searchTerms;
@end

@protocol ClearMyStellarDelegate <NSObject>
- (void) classesRemoved: (NSArray *)classes;
@end

@interface TermRequest : NSObject <JSONLoadedDelegate> {
	id<ClearMyStellarDelegate> clearMyStellarDelegate;
	NSArray *myStellarClasses;
}

- (id) initWithClearMyStellarDelegate: (id<ClearMyStellarDelegate>)delegate stellarClasses: (NSArray *)theMyStellarClasses;
@end


@interface StellarModel : NSObject {
}

// load*FromServerAndNotify methods retreive data from the server and store it in the CoreData Store
// to use the loaded data must call a retrive* method after it has been loaded

+ (BOOL) coursesCached;

+ (void) loadCoursesFromServerAndNotify: (id<CoursesLoadedDelegate>)delegate;

+ (void) loadClassesForCourse: (StellarCourse *)stellarCourse delegate: (NSObject<ClassesLoadedDelegate> *)delegate;

+ (void) loadAllClassInfo: (StellarClass *)stellarClass delegate: (id<ClassInfoLoadedDelegate>)delegate;

+ (void) executeStellarSearch: (NSString *)searchTerms delegate: (id<ClassesSearchDelegate>)delegate;

+ (void) saveClassToFavorites: (StellarClass *)class;
+ (void) removeClassFromFavorites: (StellarClass *)class;

// lookup the current semester from the server and remove old classes based on server response
+ (void) removeOldFavorites: (id<ClearMyStellarDelegate>)delegate;

+ (NSArray *) allCourses;

+ (NSArray *) myStellarClasses;

+ (NSArray *) sortedAnnouncements: (StellarClass *)class;

#pragma mark factory methods for stellar data objects (currently using CoreData)
+ (StellarCourse *) courseWithId: (NSString *)courseId;
+ (StellarClass *) classWithMasterId: (NSString *)masterId;

#pragma mark factory JSON -> Stellar
+ (StellarClass *) StellarClassFromDictionary: (NSDictionary *)aDict;
+ (StellarClassTime *) stellarTimeFromDictionary: (NSDictionary *)time class:(StellarClass *)stellarClass orderId: (NSInteger)orderId;
+ (StellarStaffMember *) stellarStaffFromName: (NSString *)name class:(StellarClass *)stellarClass type: (NSString *)type;
+ (StellarAnnouncement *) stellarAnnouncementFromDict: (NSDictionary *)dict;

@end
