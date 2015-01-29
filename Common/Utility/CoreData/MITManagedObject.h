#import <CoreData/CoreData.h>

@interface MITManagedObject : NSManagedObject
+ (NSEntityDescription*)entityDescription;
+ (NSString*)entityName;

@end
