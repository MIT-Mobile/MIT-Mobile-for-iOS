#import "StellarCourse.h"
#import "StellarClass.h"
#import "CoreDataManager.h"

@implementation StellarCourse 

@dynamic lastCache;
@dynamic lastChecksum;
@dynamic number;
@dynamic title;
@dynamic stellarClasses;
@dynamic term;

- (void)markAsNew {
	self.lastCache = [NSDate dateWithTimeIntervalSinceNow:0];
	self.term = [[NSUserDefaults standardUserDefaults] objectForKey:StellarTermKey];
	[CoreDataManager saveData];
}

@end
