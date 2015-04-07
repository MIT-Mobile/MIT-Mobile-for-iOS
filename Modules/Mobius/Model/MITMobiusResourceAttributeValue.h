#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITMobiusAttribute, MITMobiusResource;

@interface MITMobiusResourceAttributeValue : MITManagedObject

@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) MITMobiusAttribute *attribute;
@property (nonatomic, retain) MITMobiusResource *resource;

@end
