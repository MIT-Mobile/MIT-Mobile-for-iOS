
#import "StellarCache.h"
#import "StellarCourse.h"

@implementation StellarCache

+ (StellarCache *) stellarCache {
	static StellarCache *sharedInstance;
	if (!sharedInstance) {
		sharedInstance = [StellarCache new];
	}
	return sharedInstance;
}

- (id) init {
	self = [super init];
	if (self) {
		stellarClassIds = [NSMutableDictionary new];
	}
	return self;
}

- (void) dealloc {
	[stellarClassIds release];
	[super dealloc];
}

- (void) addClassIds:(NSArray *)ids forName:(NSString *)name {
	[stellarClassIds setObject:ids forKey:name];
}

+ (void) addClassIds:(NSArray *)ids forName:(NSString *)name {
	[[StellarCache stellarCache] addClassIds:ids forName:name];
}

- (NSArray *) getClassIdsForName:(NSString *)name {
	return [stellarClassIds objectForKey:name];
}

+ (NSArray *) getClassIdsForName:(NSString *)name {
	return [[StellarCache stellarCache] getClassIdsForName:name];
}

@end
