#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"

@interface MITMartyRecentSearchQuery : MITManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * text;

@end

