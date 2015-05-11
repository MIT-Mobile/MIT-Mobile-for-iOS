#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "MITManagedObject.h"
#import "MITMappedObject.h"
#import "MITMobiusAttributeValue.h"

@class MITMobiusResourceAttributeValueSet;

@interface MITMobiusResourceAttributeValue : MITManagedObject

@property (nonatomic, readonly, strong) NSString * name;
@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) MITMobiusResourceAttributeValueSet *valueSet;

@end
