#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"

@interface MITNewsRecentSearchQuery : MITManagedObject

@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * date;

@end
