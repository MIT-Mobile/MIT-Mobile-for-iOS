
#import <Foundation/Foundation.h>
#import "StellarClass.h"

@interface StellarCache : NSObject {
	NSMutableDictionary *stellarClassIds;
}

+ (StellarCache *) stellarCache;

- (void) addClassIds:(NSArray *)ids forName:(NSString *)name;
+ (void) addClassIds:(NSArray *)ids forName:(NSString *)name;

- (NSArray *) getClassIdsForName:(NSString *)name;
+ (NSArray *) getClassIdsForName:(NSString *)name;

@end
