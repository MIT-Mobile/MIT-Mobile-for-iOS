#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITMobiusObject.h"

@class MITMobiusCategory, MITMartyTemplateAttribute, MITMartyType;

@interface MITMobiusTemplate : MITMobiusObject

@property (nonatomic, retain) NSString * descriptionText;
@property (nonatomic, retain) NSSet *attributes;
@property (nonatomic, retain) NSSet *categories;
@property (nonatomic, retain) NSSet *types;
@end

@interface MITMobiusTemplate (CoreDataGeneratedAccessors)

- (void)addAttributesObject:(MITMartyTemplateAttribute *)value;
- (void)removeAttributesObject:(MITMartyTemplateAttribute *)value;
- (void)addAttributes:(NSSet *)values;
- (void)removeAttributes:(NSSet *)values;

- (void)addCategoriesObject:(MITMobiusCategory *)value;
- (void)removeCategoriesObject:(MITMobiusCategory *)value;
- (void)addCategories:(NSSet *)values;
- (void)removeCategories:(NSSet *)values;

- (void)addTypesObject:(MITMartyType *)value;
- (void)removeTypesObject:(MITMartyType *)value;
- (void)addTypes:(NSSet *)values;
- (void)removeTypes:(NSSet *)values;

@end
