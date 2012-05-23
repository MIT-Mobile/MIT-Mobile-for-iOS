#import <Foundation/Foundation.h>
#import "ConnectionWrapper.h"
#import "StellarCourse.h"
#import "StellarClass.h"
#import "StellarClassTime.h"
#import "StellarStaffMember.h"

extern NSString * const MyStellarChanged;

#pragma mark Course Loading 
@protocol CoursesLoadedDelegate <NSObject>
- (void) coursesLoaded;
@end

#pragma mark Class List Loading

@protocol ClassesLoadedDelegate <NSObject>
- (void) classesLoaded: (NSArray *)classes;
- (void) handleCouldNotReachStellar;
- (id<UIAlertViewDelegate>) standardErrorAlertDelegate;  
@end

#pragma mark Class Info Loading

@protocol ClassInfoLoadedDelegate <NSObject>
- (void) generalClassInfoLoaded: (StellarClass *)class;
- (void) initialAllClassInfoLoaded: (StellarClass *)class;
- (void) finalAllClassInfoLoaded: (StellarClass *)class;
- (void) handleClassNotFound;
- (void) handleCouldNotReachStellar;
@end

@protocol ClassesSearchDelegate <NSObject>
- (void) searchComplete: (NSArray *)classes searchTerms: (NSString *)searchTerms;
- (void) handleCouldNotReachStellarWithSearchTerms: (NSString *)searchTerms;
@end

@protocol ClearMyStellarDelegate <NSObject>
- (void) classesRemoved: (NSArray *)classes;
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
