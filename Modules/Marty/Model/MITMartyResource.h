#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITMartyObject.h"

@class MITMartyCategory, MITMartyResourceAttribute, MITMartyResourceOwner, MITMartyTemplate, MITMartyType;

@interface MITMartyResource : MITMartyObject

@property (nonatomic, retain) NSString * dlc;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * reservable;
@property (nonatomic, retain) NSString * room;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSSet *attributes;
@property (nonatomic, retain) MITMartyCategory *category;
@property (nonatomic, retain) NSSet *owners;
@property (nonatomic, retain) MITMartyTemplate *template;
@property (nonatomic, retain) MITMartyType *type;
@end

@interface MITMartyResource (CoreDataGeneratedAccessors)

- (void)addAttributesObject:(MITMartyResourceAttribute *)value;
- (void)removeAttributesObject:(MITMartyResourceAttribute *)value;
- (void)addAttributes:(NSSet *)values;
- (void)removeAttributes:(NSSet *)values;

- (void)addOwnersObject:(MITMartyResourceOwner *)value;
- (void)removeOwnersObject:(MITMartyResourceOwner *)value;
- (void)addOwners:(NSSet *)values;
- (void)removeOwners:(NSSet *)values;

@end
