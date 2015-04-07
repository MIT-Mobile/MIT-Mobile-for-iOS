#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"

@class MITMobiusRecentSearchList;

@interface MITMobiusRecentSearchQuery : MITManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) MITMobiusRecentSearchList *search;

@end
