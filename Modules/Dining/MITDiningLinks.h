#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@interface MITDiningLinks : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * url;

@end
