#import <Foundation/Foundation.h>

@interface MITMapCategory : NSObject <NSSecureCoding,NSCopying>
@property (copy) NSString *name;
@property (copy) NSString *identifier;
@property (copy) NSOrderedSet *subcategories;

- (id)initWithDictionary:(NSDictionary*)placeDictionary;
- (BOOL)hasSubcategories;
@end
