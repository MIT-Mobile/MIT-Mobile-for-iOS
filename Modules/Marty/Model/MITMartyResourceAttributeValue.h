#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITMobiusResourceAttribute;

@interface MITMartyResourceAttributeValue : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) MITMobiusResourceAttribute *attribute;

@end
