
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
	if(self = [super init]) {
		stellarClassLists = [NSMutableDictionary new];
		stellarClassInfo = [NSMutableDictionary new];
	}
	return self;
}

- (void) dealloc {
	[stellarClassLists release];
	[super dealloc];
}

+ (void) addClassList:(NSArray *)classList forCourse:(StellarCourse *)stellarCourse {
	[[StellarCache stellarCache] addClassList:classList forCourse:stellarCourse];
}

- (void) addClassList:(NSArray *)classList forCourse:(StellarCourse *)stellarCourse {
	[stellarClassLists setObject:classList forKey:stellarCourse.number];
}

+ (NSArray *) getClassListForCourse: (StellarCourse *)stellarCourse {
	return [[StellarCache stellarCache] getClassListForCourse:stellarCourse];
}

- (NSArray *) getClassListForCourse: (StellarCourse *)stellarCourse {
	return (NSArray *)[stellarClassLists objectForKey:stellarCourse.number];
}

+ (StellarClass *) getGeneralClassInfo: (StellarClass *)class {
	return [[StellarCache stellarCache] getGeneralClassInfo:class];
}
	
/**
 * the method is a little tricky, checks to see if there is GENERAL class information
 * contained in the class argument (if so it uses that information to overwrite the current cache
 * otherwise it just checks to see if this information is contained in the class
 */
- (StellarClass *) getGeneralClassInfo: (StellarClass *)class {
	StellarClass *cachedResult = [stellarClassInfo objectForKey:class.masterSubjectId];
	if(class.name) {
		if(cachedResult) {
			if([[class.announcement allObjects] count] == 0) {
				[class addAnnouncement:cachedResult.announcement];
			}
			class.isFavorited = cachedResult.isFavorited;
		}
		//overwrite the old value
		[stellarClassInfo setObject:class forKey:class.masterSubjectId];
		cachedResult = class;
	}	
	return cachedResult;
}

+ (StellarClass *) getAllClassInfo: (StellarClass *)class {
	return [[StellarCache stellarCache] getAllClassInfo:class];
}

- (StellarClass *) getAllClassInfo: (StellarClass *)class {
	return [stellarClassInfo objectForKey:class.masterSubjectId];
}

+ (void) addAllClassInfo: (StellarClass *)class {
	[[StellarCache stellarCache] addAllClassInfo:class];
}	

- (void) addAllClassInfo: (StellarClass *)class {
	[stellarClassInfo setObject:class forKey:class.masterSubjectId];
}
		
@end
