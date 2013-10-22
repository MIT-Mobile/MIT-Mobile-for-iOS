#import <Foundation/Foundation.h>

@interface MITMapCategory : NSObject <NSSecureCoding,NSCopying>
@property (readonly,copy) NSString *name;
@property (readonly,copy) NSString *identifier;
@property (readonly,copy) NSOrderedSet *subcategories;
@property (readonly,copy) MITMapCategory *parent;

- (id)initWithDictionary:(NSDictionary*)placeDictionary;
- (BOOL)hasSubcategories;

- (NSString*)canonicalName;
@end
