#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITMobiusAttribute, MITMobiusAttributeValue;

@interface MITMobiusAttributeValueSet : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *values;
@property (nonatomic, retain) MITMobiusAttribute *attribute;
@end

@interface MITMobiusAttributeValueSet (CoreDataGeneratedAccessors)

- (void)addValuesObject:(MITMobiusAttributeValue *)value;
- (void)removeValuesObject:(MITMobiusAttributeValue *)value;
- (void)addValues:(NSSet *)values;
- (void)removeValues:(NSSet *)values;

@end
