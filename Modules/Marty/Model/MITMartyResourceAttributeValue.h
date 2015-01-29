#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITMartyResourceAttribute;

@interface MITMartyResourceAttributeValue : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) MITMartyResourceAttribute *attribute;

@end
