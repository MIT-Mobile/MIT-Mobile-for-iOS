#import "MITEventsRecentSearches.h"

static NSString *const kMITCalendarEventRecentSearchesDefaultsKey = @"kMITCalendarEventRecentSearchesDefaultsKey";
static NSInteger const kMITCalendarEventRecentSearchesLimit = 50;

@implementation MITEventsRecentSearches

+ (void)saveRecentEventSearch:(NSString *)recentSearch
{
    NSMutableOrderedSet *mutableRecents = [[self recentSearches] mutableCopy];
    
    NSUInteger indexOfMatchingRecent = [mutableRecents indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        NSString *recent = obj;
        if ([[recent lowercaseString] isEqualToString:[recentSearch lowercaseString]]) {
            *stop = YES;
            return YES;
        } else {
            return NO;
        }
    }];
    
    if (indexOfMatchingRecent != NSNotFound) {
        [mutableRecents removeObjectAtIndex:indexOfMatchingRecent];
    }
    
    [mutableRecents insertObject:recentSearch atIndex:0];
    
    if (mutableRecents.count > kMITCalendarEventRecentSearchesLimit) {
        [mutableRecents removeObjectAtIndex:kMITCalendarEventRecentSearchesLimit];
    }
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:[NSOrderedSet orderedSetWithOrderedSet:mutableRecents]] forKey:kMITCalendarEventRecentSearchesDefaultsKey];
}

+ (NSOrderedSet *)recentSearches
{
    NSOrderedSet *recents = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:kMITCalendarEventRecentSearchesDefaultsKey]];
    if (!recents) {
        recents = [NSOrderedSet orderedSet];
    }
    return recents;
}

@end
