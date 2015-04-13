#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITMobiusAttribute,MITMobiusSearchOption;

@interface MITMobiusAttributeValue : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) MITMobiusAttribute *attribute;
@property (nonatomic, retain) NSSet *searchOptions;
@end

@interface MITMobiusAttributeValue (CoreDataGeneratedAccessors)

- (void)addSearchOptionsObject:(MITMobiusSearchOption *)value;
- (void)removeSearchOptionsObject:(MITMobiusSearchOption *)value;
- (void)addSearchOptions:(NSSet *)values;
- (void)removeSearchOptions:(NSSet *)values;

@end
