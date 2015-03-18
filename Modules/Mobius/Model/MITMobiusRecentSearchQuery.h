#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"

@interface MITMobiusRecentSearchQuery : MITManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * text;

@end

