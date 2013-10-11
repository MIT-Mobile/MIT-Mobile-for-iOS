#import <Foundation/Foundation.h>

@interface MITMapCategory : NSObject <NSSecureCoding,NSCopying>
@property (copy) NSString *name;
@property (copy) NSString *identifier;
@property (copy) NSOrderedSet *subcategories;
@property (copy) MITMapCategory *parent;

- (id)initWithDictionary:(NSDictionary*)placeDictionary;
- (BOOL)hasSubcategories;
@end
