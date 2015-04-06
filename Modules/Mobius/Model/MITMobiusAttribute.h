#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITMobiusAttributeValueSet, MITMobiusResource, MITMobiusAttributeValue;

@interface MITMobiusAttribute : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * fieldType;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSString * widgetType;
@property (nonatomic, retain) NSSet *resources;
@property (nonatomic, retain) MITMobiusAttributeValueSet *valueSet;
@property (nonatomic, retain) NSOrderedSet *values;
@end

@interface MITMobiusAttribute (CoreDataGeneratedAccessors)

- (void)addResourcesObject:(MITMobiusResource *)value;
- (void)removeResourcesObject:(MITMobiusResource *)value;
- (void)addResources:(NSSet *)values;
- (void)removeResources:(NSSet *)values;

- (void)addValuesObject:(MITMobiusAttributeValue *)value;
- (void)removeValuesObject:(MITMobiusAttributeValue *)value;
- (void)addValues:(NSOrderedSet *)values;
- (void)removeValues:(NSOrderedSet *)values;

@end
