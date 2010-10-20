
#import <Foundation/Foundation.h>
#import "StellarClass.h"

@interface StellarCache : NSObject {
	NSMutableDictionary *stellarClassLists;
	NSMutableDictionary *stellarClassInfo;
}

+ (StellarCache *) stellarCache;

- (void) addClassList:(NSArray *)classList forCourse:(StellarCourse *)stellarCourse;
+ (void) addClassList:(NSArray *)classList forCourse:(StellarCourse *)stellarCourse;

- (NSArray *) getClassListForCourse: (StellarCourse *)stellarCourse;
+ (NSArray *) getClassListForCourse: (StellarCourse *)stellarCourse;

- (StellarClass *) getGeneralClassInfo: (StellarClass *)class;
+ (StellarClass *) getGeneralClassInfo: (StellarClass *)class;

- (StellarClass *) getAllClassInfo: (StellarClass *)class;
+ (StellarClass *) getAllClassInfo: (StellarClass *)class;

- (void) addAllClassInfo: (StellarClass *)class;
+ (void) addAllClassInfo: (StellarClass *)class;






@end
