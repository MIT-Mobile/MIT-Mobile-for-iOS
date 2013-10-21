#import <Foundation/Foundation.h>

@interface MITMapCategory : NSObject <NSSecureCoding,NSCopying>
@property (readonly,copy) NSString *name;
@property (readonly,copy) NSString *identifier;
@property (readonly,copy) NSOrderedSet *subcategories;
@property (readonly,copy) MITMapCategory *parent;

- (id)initWithDictionary:(NSDictionary*)placeDictionary;
- (BOOL)hasSubcategories;

/** Returns an array of category names as strings.
 *  The zeroth index is the name of the first category in the
 *  tree and the last index is the receiver.
 */
- (NSArray*)pathComponents;
@end
