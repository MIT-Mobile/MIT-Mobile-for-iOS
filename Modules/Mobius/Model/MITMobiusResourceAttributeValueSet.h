#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITMobiusResource, MITMobiusResourceAttributeValue;

@interface MITMobiusResourceAttributeValueSet : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSSet *values;
@property (nonatomic, retain) MITMobiusResource *attribute;
@end

@interface MITMobiusResourceAttributeValueSet (CoreDataGeneratedAccessors)

- (void)addValuesObject:(MITMobiusResourceAttributeValue *)value;
- (void)removeValuesObject:(MITMobiusResourceAttributeValue *)value;
- (void)addValues:(NSSet *)values;
- (void)removeValues:(NSSet *)values;

@end
