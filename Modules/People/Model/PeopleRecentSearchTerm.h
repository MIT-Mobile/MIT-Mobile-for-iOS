#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"

@class PeopleRecentSearchTermList;

@interface PeopleRecentSearchTerm : MITManagedObject

@property (nonatomic, retain) NSString * recentSearchTerm;
@property (nonatomic, retain) PeopleRecentSearchTermList *listOfRecentSearchTerms;

@end
